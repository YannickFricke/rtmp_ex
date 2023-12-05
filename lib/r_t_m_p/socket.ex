defmodule RTMP.Socket do
  @moduledoc """
  This module is a higher-order module for gen_tcp related operations.
  """

  @typedoc """
  A re-export of the gen_tcp socket type.
  """
  @type t() :: :gen_tcp.socket()

  @doc """
  Reads the given amount of bytes from the socket within the given timeout.
  """
  @spec read(
          socket :: t(),
          amount_of_bytes :: pos_integer(),
          timeout :: timeout()
        ) :: {:ok, binary()} | {:error, :closed | :timeout | :inet.posix()}
  def read(socket, amount_of_bytes, timeout \\ RTMP.default_timeout()) do
    :gen_tcp.recv(socket, amount_of_bytes, timeout)
  end

  @doc """
  Writes the given data to the socket.
  """
  @spec write(
          socket :: t(),
          data :: binary()
        ) :: :ok | {:error, :closed | {:timeout, binary()} | :inet.posix()}
  def write(socket, data) do
    :gen_tcp.send(socket, data)
  end
end
