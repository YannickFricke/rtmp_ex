defmodule RTMP.ClientHandler do
  @moduledoc """
  Provides callbacks for RTMP clients.

  This behaviour provides callbacks for various events within the lifecycle of a RTMP connection.

  ## Example usage

  ```elixir
  defmodule MyApp.RtmpClientHandler do
    use RTMP.ClientHandler

    def on_tcp_connect(_ip_address, port), do: :ok

    def on_client_disconnect(_ip_address, port), do: :ok
  end
  ```
  """

  @doc """
  Invokes the given function when it is exported by the given module.

  If the function is not exported then the default result will be returned.
  """
  @spec invoke_if_exported(
          module :: module(),
          function_name :: atom(),
          arity :: non_neg_integer(),
          function_arguments :: list(term()),
          default_result :: term()
        ) :: term()
  def invoke_if_exported(module, function_name, arity, function_arguments \\ [], default_result \\ :ok) do
    if function_exported?(module, function_name, arity) do
      apply(module, function_name, function_arguments)
    else
      default_result
    end
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour RTMP.ClientHandler
    end
  end

  @doc """
  Gets called when a client connects to the RTMP server.
  """
  @callback on_tcp_connect(
              ip_address :: :inet.ip_address(),
              port :: :inet.port_number()
            ) :: :ok | {:disconnect, reason :: String.t() | atom()}

  @doc """
  Gets called when a client disconnects from the RMTP server.

  The metadata will be empty when the client disconnects before they were exchanged.
  """
  @callback on_client_disconnect(
              ip_address :: :inet.ip_address(),
              port :: :inet.port_number(),
              metadata :: map()
            ) :: term()

  @optional_callbacks on_tcp_connect: 2,
                      on_client_disconnect: 3
end
