defmodule RTMP.Socket do
  @moduledoc """
  This module is a higher-order module for gen_tcp related operations.
  """

  @typedoc """
  A re-export of the gen_tcp socket type.
  """
  @type t() :: :gen_tcp.socket()

  @type read_result(success_type) :: {:ok, success_type} | {:error, :closed | :timeout | :invalid_data | :inet.posix()}

  @type write_result() :: :ok | {:error, :closed | {:timeout, binary()} | :inet.posix()}

  @doc """
  Reads the given amount of bytes from the socket within the given timeout.
  """
  @spec read(
          socket :: t(),
          amount_of_bytes :: pos_integer(),
          timeout :: timeout()
        ) :: read_result(binary())
  def read(socket, amount_of_bytes, timeout \\ RTMP.default_timeout()) do
    :gen_tcp.recv(socket, amount_of_bytes, timeout)
  end

  @doc """
  Writes the given data to the socket.
  """
  @spec write(
          socket :: t(),
          data :: iodata()
        ) :: write_result()
  def write(socket, data) do
    :gen_tcp.send(socket, data)
  end

  @doc """
  Closes the given socket.
  """
  @spec close(socket :: t()) :: :ok
  def close(socket), do: :gen_tcp.close(socket)
end
