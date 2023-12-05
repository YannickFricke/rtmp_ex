defmodule RTMP.ClientConnection do
  @moduledoc false

  use GenServer, restart: :temporary

  @name __MODULE__

  @type state() :: %{
          socket: RTMP.Socket.t(),
          ip: :inet.ip_address(),
          port: :inet.port_number()
        }

  def start_link(options), do: GenServer.start_link(@name, options)

  @spec init(options :: Keyword.t()) :: {:ok, state()}
  def init(options) do
    client_socket = Keyword.get(options, :socket)
    client_ip = Keyword.get(options, :ip_address)
    client_port = Keyword.get(options, :port)

    {
      :ok,
      %{socket: client_socket, ip: client_ip, port: client_port}
    }
  end
end
