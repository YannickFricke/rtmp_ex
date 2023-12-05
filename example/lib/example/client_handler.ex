defmodule Example.ClientHandler do
  use RTMP.ClientHandler

  require Logger

  def on_tcp_connect(ip_address, port) do
    ip_address_string = RTMP.ip_to_string(ip_address)

    Logger.info("Got new connection from #{ip_address_string}:#{port}")
  end

  def on_client_disconnect(ip_address, port, _metadata) do
    ip_address_string = RTMP.ip_to_string(ip_address)

    Logger.info("Client #{ip_address_string}:#{port} disconnected")
  end
end
