defmodule RTMP.Socket do
  @moduledoc """
  """

  @typedoc """
  A re-export of the gen_tcp socket type.
  """
  @type t() :: :gen_tcp.socket()

  @spec read(
          socket :: t(),
          amount_of_bytes :: pos_integer(),
          timeout :: timeout()
        ) :: {:ok, binary()} | {:error, :closed | :timeout | :inet.posix()}
  def read(socket, amount_of_bytes, timeout \\ RTMP.default_timeout()) do
    :gen_tcp.recv(socket, amount_of_bytes, timeout)
  end

  @spec write(
          socket :: t(),
          data :: binary()
        ) :: :ok | {:error, :closed | {:timeout, binary()} | :inet.posix()}
  def write(socket, data) do
    :gen_tcp.send(socket, data)
  end
end
