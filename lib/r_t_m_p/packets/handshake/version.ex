defmodule RTMP.Packets.Handshake.Version do
  @moduledoc false

  alias RTMP.Socket

  @type t() :: %__MODULE__{
          version: non_neg_integer()
        }

  defstruct [:version]

  @spec read(socket :: Socket.t(), timeout :: timeout()) :: Socket.read_result(t())
  def read(socket, timeout \\ RTMP.default_timeout()) do
    case Socket.read(socket, 1, timeout) do
      {:ok, <<version::size(8)>>} ->
        {:ok,
         %__MODULE__{
           version: version
         }}

      error ->
        error
    end
  end

  @spec write(socket :: Socket.t(), version :: integer()) :: Socket.write_result()
  def write(socket, version), do: Socket.write(socket, <<version::size(8)>>)
end
