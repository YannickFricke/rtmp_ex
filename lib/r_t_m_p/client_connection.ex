defmodule RTMP.ClientConnection do
  @moduledoc false

  use GenServer, restart: :temporary

  alias RTMP.ClientHandler
  alias RTMP.Socket

  require Logger

  @name __MODULE__

  @typep state() :: %{
           socket: RTMP.Socket.t(),
           ip: :inet.ip_address(),
           port: :inet.port_number(),
           client_handler: module()
         }

  # Client API

  def start_link(options), do: GenServer.start_link(@name, options)

  def shutdown(name_or_pid), do: GenServer.call(name_or_pid, {:client, :shutdown})

  # Server API

  @impl GenServer
  @spec init(options :: Keyword.t()) :: {:ok, state()}
  def init(options) do
    client_socket = Keyword.get(options, :socket)
    client_ip = Keyword.get(options, :ip_address)
    client_port = Keyword.get(options, :port)
    client_handler = Keyword.get(options, :client_handler)

    Process.flag(:trap_exit, true)

    {
      :ok,
      %{socket: client_socket, ip: client_ip, port: client_port, client_handler: client_handler}
    }
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
end
