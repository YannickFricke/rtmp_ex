defmodule RTMP do
  @moduledoc """
  Documentation for `RTMP`.
  """

  @typedoc """
  A re-export of the gen_tcp socket type.
  """
  @type socket() :: :gen_tcp.socket()

  @doc """
  Returns the default port (1935) for the RTMP protocol.

  ## Examples

  ```elixir
  iex> RTMP.default_port()
  1935
  ```
  """
  @spec default_port() :: 1935
  def default_port, do: 1935
end
