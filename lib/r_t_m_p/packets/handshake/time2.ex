defmodule RTMP.Packets.Handshake.Time2 do
  @moduledoc false

  alias RTMP.Socket

  @type t() :: %__MODULE__{
          time1: non_neg_integer(),
          time2: non_neg_integer(),
          random_data: binary()
        }

  defstruct [:time1, :time2, :random_data]

  @spec read(socket :: Socket.t(), timeout :: timeout()) :: Socket.read_result(t())
  def read(socket, timeout \\ RTMP.default_timeout()) do
    case Socket.read(socket, 1536, timeout) do
      {:ok, <<time1::integer-size(4 * 8), time2::integer-size(4 * 8), random_data::binary>>} ->
        {:ok,
         %__MODULE__{
           time1: time1,
           time2: time2,
           random_data: random_data
         }}

      {:ok, _data} ->
        {:error, :invalid_data}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec write(
          socket :: Socket.t(),
          time1 :: non_neg_integer(),
          time2 :: non_neg_integer(),
          random_data :: binary()
        ) :: Socket.write_result()
  def write(socket, time1, time2, random_data) do
    Socket.write(socket, <<time1::integer-size(4 * 8), time2::integer-size(4 * 8), random_data::binary>>)
  end
end
