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
  @spec default_port() :: :inet.port_number()
  def default_port, do: 1935

  @doc """
  Returns the default timeout for network operations.

  ## Examples

  ```elixir
  iex> RTMP.default_timeout()
  5000
  ```
  """
  @spec default_timeout() :: non_neg_integer()
  def default_timeout, do: :timer.seconds(5)

  @doc """
  Stringifies the given IP adress

  ## Examples

  Stringifying an IPv4 address

  ```elixir
  iex> RTMP.ip_to_string({127, 0, 0, 1})
  "127.0.0.1"
  ```

  Stringifying an IPv8 address

  ```elixir
  iex> RTMP.ip_to_string({0, 0, 0, 0, 0, 0, 0, 1})
  "0:0:0:0:0:0:0:1"
  ```
  """
  @spec ip_to_string(ip_address :: :inet.ip_address()) :: binary()
  def ip_to_string({_, _, _, _} = ip_v4_address), do: ip_v4_address |> Tuple.to_list() |> Enum.join(".")

  def ip_to_string({_, _, _, _, _, _, _, _} = ip_v6_address), do: ip_v6_address |> Tuple.to_list() |> Enum.join(":")
end
