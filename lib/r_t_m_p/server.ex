defmodule RTMP.Server do
  @moduledoc """
  Implements a RTMP server based on this specification:
  - [HTML](https://rtmp.veriskope.com/docs/spec/)
  - [PDF](https://rtmp.veriskope.com/pdf/rtmp_specification_1.0.pdf)

  It accepts the following options:

  | Name           | Required | Description                                                                                                                                                 |
  | :------------- | :------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | client_handler | Yes      | The module which provides callbacks for the lifecycle of a RTMP connection                                                                                  |
  | name           | No       | The name of the GenServer (defaults to `RTMP.Server` for a single instance)                                                                                 |
  | ip             | No       | The IP address to which the TCP listener should bind to                                                                                                     |
  | port           | No       | The port on which the TCP listener should use                                                                                                               |
  | send_timeout   | No       | The default send timeout before a connection is considered as timeouted. Defaults to `RTMP.default_timeout/0`.                                              |
  | accept_timeout | No       | The amount of time to wait until a new socket connects. A low value enables the RTMP server to process more messages. Defaults to `RTMP.default_timeout/0`. |
  """
  @moduledoc since: "0.0.0"

  use GenServer, restart: :transient

  alias RTMP.ClientConnection
  alias RTMP.ClientHandler
  alias RTMP.ConnectionSupervisor
  alias RTMP.Socket

  require Logger

  # The internal state of the RTMP server
  @typep state() :: %{
           port: :inet.port_number(),
           server_socket: RTMP.Socket.t(),
           client_handler: module(),
           accept_timeout: pos_integer()
         }

  @name __MODULE__

  # Client API

  @spec start_link(options :: keyword()) :: GenServer.on_start()
  def start_link(options) do
    genserver_registration_name = Keyword.get(options, :name, @name)

    GenServer.start_link(@name, options, name: genserver_registration_name)
  end

  @doc """
  Shuts the given RTMP server process by its name or pid asynchronously down.

  It also disconnects all clients which were connected through the given RTMP server.
  """
  @spec shutdown(name_or_pid :: GenServer.name() | pid()) :: :ok
  def shutdown(name_or_pid \\ RTMP.Server), do: GenServer.cast(name_or_pid, :shutdown)

  # Server API

  @impl GenServer
  @spec init(options :: keyword()) :: {:ok, state()}
  def init(options) do
    ip = Keyword.get(options, :ip, {0, 0, 0, 0})
    port = Keyword.get(options, :port, RTMP.default_port())
    send_timeout = Keyword.get(options, :send_timeout, RTMP.default_timeout())
    accept_timeout = Keyword.get(options, :accept_timeout, RTMP.default_timeout())

    client_handler =
      Keyword.get(options, :client_handler) ||
        raise "The RTMP.Server requires a client handler module which is passed via client_handler"

    Process.flag(:trap_exit, true)

    listen_options = [
      :binary,
      active: false,
      reuseaddr: true,
      reuseport: true,
      ip: ip,
      send_timeout: send_timeout
    ]

    with {:ok, server_socket} <- :gen_tcp.listen(port, listen_options) do
      # After initialization the RTMP server should accept clients
      accept_client()

      {:ok,
       %{
         port: port,
         server_socket: server_socket,
         client_handler: client_handler,
         accept_timeout: accept_timeout
       }}
    end
  end

  @impl GenServer
  def handle_info(
        {:client, :accept},
        %{server_socket: server_socket, client_handler: client_handler, accept_timeout: accept_timeout} = state
      ) do
    should_accept_new_clients =
      case :gen_tcp.accept(server_socket, accept_timeout) do
        {:ok, accepted_client_socket} ->
          case :inet.peername(accepted_client_socket) do
            {:ok, {client_ip, client_port}} ->
              client_ip_string = RTMP.ip_to_string(client_ip)

              case ClientHandler.invoke_if_exported(client_handler, :on_tcp_connect, 2, [client_ip, client_port]) do
                :ok ->
                  start_client_task(accepted_client_socket, client_ip, client_port, client_handler)

                {:disconnect, reason} ->
                  Logger.debug("[RTMP] Disconnecting client #{client_ip_string}:#{client_port}: #{inspect(reason)}")

                  Socket.close(accepted_client_socket)
              end

            value ->
              Logger.warning("[RTMP] Could not get remote IP + port: #{inspect(value)}")

              Socket.close(accepted_client_socket)
          end

          true

        {:error, :closed} ->
          # The server socket was closed while accepting new clients
          false

        {:error, :timeout} ->
          # No new client connected within the specified timeout
          true

        {:error, reason} ->
          Logger.warning("[RTMP] Could not accept client socket: #{inspect(reason)}")

          true
      end

    if should_accept_new_clients do
      # Accept new clients since the current one was handled
      # This also gives the GenServer time to handle other messages aswell
      accept_client()
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    case Registry.lookup(RTMP.ClientMetaRegistry, pid) do
      [] ->
        Logger.warning(
          "[RTMP] Could not find ref for pid #{inspect(pid)} - most likely the socket remains open until the program stops"
        )

      [
        {_process,
         %{
           socket: client_socket,
           ip: client_ip,
           port: client_port
         }}
      ] ->
        ip_address_string = RTMP.ip_to_string(client_ip)

        Logger.debug(
          "[RTMP] Closing connection to #{ip_address_string}:#{client_port} since the corresponding ClientConnection went down"
        )

        Socket.close(client_socket)

        Registry.unregister(RTMP.ClientMetaRegistry, pid)
    end

    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    server_socket = Map.get(state, :server_socket)

    if server_socket != nil do
      Socket.close(server_socket)
    end

    Enum.each(Registry.keys(RTMP.ClientMetaRegistry, self()), fn client_connection_pid ->
      if Process.alive?(client_connection_pid) do
        ClientConnection.shutdown(client_connection_pid)

        Registry.unregister(RTMP.ClientMetaRegistry, client_connection_pid)
      end
    end)
  end

  @impl GenServer
  def handle_cast(:shutdown, state) do
    {:stop, :normal, state}
  end

  # Sends the current process the `{:client, :accept}` message which needs to be handled by `handle_info/2`
  defp accept_client, do: send(self(), {:client, :accept})

  defp start_client_task(client_socket, client_ip, client_port, client_handler) do
    client_ip_string = RTMP.ip_to_string(client_ip)

    case ConnectionSupervisor.start_client_task(client_socket, client_ip, client_port, client_handler) do
      {:ok, pid} ->
        :gen_tcp.controlling_process(client_socket, pid)

        Process.monitor(pid)

        Registry.register(RTMP.ClientMetaRegistry, pid, %{
          socket: client_socket,
          ip: client_ip,
          port: client_port
        })

      {:ok, pid, _info} ->
        :gen_tcp.controlling_process(client_socket, pid)

        Process.monitor(pid)

        Registry.register(RTMP.ClientMetaRegistry, pid, %{
          socket: client_socket,
          ip: client_ip,
          port: client_port
        })

      :ignore ->
        Socket.close(client_socket)

      {:error, reason} ->
        Logger.warning(
          "[RTMP] Could not start ClientConnection for client #{client_ip_string}:#{client_port}: #{inspect(reason)}"
        )

        Socket.close(client_socket)
    end
  end
end
