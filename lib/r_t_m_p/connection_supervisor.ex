defmodule RTMP.ConnectionSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias RTMP.ClientConnection

  @name __MODULE__

  def start_link(_options) do
    DynamicSupervisor.start_link(@name, nil, name: @name)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_client_task(
          client_socket :: RTMP.socket(),
          remote_ip_address :: :inet.ip_address(),
          remote_port :: :inet.port_number()
        ) :: DynamicSupervisor.on_start_child()
  def start_client_task(client_socket, remote_ip_address, remote_port) do
    DynamicSupervisor.start_child(
      @name,
      {ClientConnection,
       [
         socket: client_socket,
         ip_address: remote_ip_address,
         port: remote_port
       ]}
    )
  end
end
