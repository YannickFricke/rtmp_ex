defmodule RTMP.ClientConnection do
  @moduledoc false

  use GenServer, restart: :temporary

  alias RTMP.ClientHandler
  alias RTMP.Packets.Handshake.Time1
  alias RTMP.Packets.Handshake.Time2
  alias RTMP.Packets.Handshake.Version
  alias RTMP.Socket

  require Logger

  @name __MODULE__

  @default_chunk_size_in_bytes 128

  @typep state() :: %{
           socket: RTMP.Socket.t(),
           ip: :inet.ip_address(),
           port: :inet.port_number(),
           client_handler: module(),
           receiving_chunk_size_in_bytes: pos_integer()
         }

  # Client API

  def start_link(options), do: GenServer.start_link(@name, options)

  def shutdown(name_or_pid), do: GenServer.call(name_or_pid, {:client, :shutdown})

  # Server API

  @impl GenServer
  @spec init(options :: Keyword.t()) :: {:ok, state(), {:continue, {:handshake, :version}}}
  def init(options) do
    client_socket = Keyword.get(options, :socket)
    client_ip = Keyword.get(options, :ip_address)
    client_port = Keyword.get(options, :port)
    client_handler = Keyword.get(options, :client_handler)

    Process.flag(:trap_exit, true)

    {
      :ok,
      %{
        socket: client_socket,
        ip: client_ip,
        port: client_port,
        client_handler: client_handler,
        receiving_chunk_size_in_bytes: @default_chunk_size_in_bytes
      },
      {:continue, {:handshake, :version}}
    }
  end

  @impl GenServer
  def handle_continue({:handshake, :version}, %{socket: client_socket, ip: ip_address, port: port} = state) do
    ip_address_string = RTMP.ip_to_string(ip_address)

    case Version.read(client_socket) do
      {:ok, %Version{version: client_version}} when client_version == 3 ->
        case Version.write(client_socket, client_version) do
          :ok ->
            {:noreply, state, {:continue, {:handshake, :time1}}}

          {:error, reason} ->
            Logger.info(
              "Disconnecting client #{ip_address_string}:#{port} since the version packet could not be send: #{inspect(reason)}"
            )

            Socket.close(client_socket)

            {:stop, :normal, state}
        end

      {:ok, %Version{version: unsupported_version}} ->
        Logger.info(
          "Disconnecting client #{ip_address_string}:#{port} due to an unsupported version: #{unsupported_version}"
        )

        Socket.close(client_socket)

        {:stop, :normal, state}

      {:error, reason} ->
        Logger.info(
          "Disconnecting client #{ip_address_string}:#{port} since the version packet could not be read: #{inspect(reason)}"
        )

        Socket.close(client_socket)

        {:stop, :normal, state}
    end
  end

  def handle_continue({:handshake, :time1}, %{socket: client_socket, ip: ip_address, port: port} = state) do
    ip_address_string = RTMP.ip_to_string(ip_address)

    case Time1.read(client_socket) do
      {:ok, %Time1{time1: time1, random_data: random_data}} ->
        case Time1.write(client_socket, time1, random_data) do
          :ok ->
            {:noreply, state, {:continue, {:handshake, :time2, time1}}}

          {:error, reason} ->
            Logger.info(
              "Disconnecting client #{ip_address_string}:#{port} since the time1 packet could not be send: #{inspect(reason)}"
            )

            Socket.close(client_socket)

            {:stop, :normal, state}
        end

      {:error, reason} ->
        Logger.info(
          "Disconnecting client #{ip_address_string}:#{port} since the time1 packet could not be read: #{inspect(reason)}"
        )

        Socket.close(client_socket)

        {:stop, :normal, state}
    end
  end

  def handle_continue({:handshake, :time2, time1}, %{socket: client_socket, ip: ip_address, port: port} = state) do
    ip_address_string = RTMP.ip_to_string(ip_address)

    case Time2.read(client_socket) do
      {:ok,
       %Time2{
         time1: ^time1,
         time2: time2,
         random_data: random_data
       }} ->
        case Time2.write(client_socket, time1, time2, random_data) do
          :ok ->
            Logger.debug("Handshake for client #{ip_address_string}:#{port} was successful")

            read_packet()

            {:noreply, state}

          {:error, reason} ->
            Logger.info(
              "Disconnecting client #{ip_address_string}:#{port} since the time2 packet could not be send: #{inspect(reason)}"
            )

            Socket.close(client_socket)

            {:stop, :normal, state}
        end

      {:ok,
       %Time2{
         time1: wrong_time1
       }} ->
        Logger.info(
          "Disconnecting client #{ip_address_string}:#{port} since the time2 packet contains a wrong \"time1\" field: Expected #{time1} - Got #{wrong_time1}"
        )

        Socket.close(client_socket)

        {:stop, :normal, state}

      {:error, reason} ->
        Logger.info(
          "Disconnecting client #{ip_address_string}:#{port} since the time2 packet could not be read: #{inspect(reason)}"
        )

        Socket.close(client_socket)

        {:stop, :normal, state}
    end
  end

  def handle_continue(:shutdown, %{socket: socket, client_handler: client_handler} = state) do
    RTMP.ClientMetaRegistry
    |> Registry.lookup(self())
    |> case do
      [] ->
        nil

      [
        {_process,
         %{
           ip: client_ip,
           port: client_port
         }}
      ] ->
        ClientHandler.invoke_if_exported(
          client_handler,
          :on_client_disconnect,
          3,
          [
            client_ip,
            client_port,
            %{}
          ]
        )
    end

    Socket.close(socket)

    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_call({:client, :shutdown}, _from, state) do
    {:reply, nil, state, {:continue, :shutdown}}
  end

  @impl GenServer
  def handle_info({:packet, :read}, state) do
    {:noreply, state}
  end

  defp read_packet, do: send(self(), {:packet, :read})
end
