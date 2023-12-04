defmodule RTMP.Supervisor do
  @moduledoc false

  use Supervisor

  alias RTMP.ConnectionSupervisor

  @name __MODULE__

  def start_link(_options) do
    Supervisor.start_link(@name, nil, name: @name)
  end

  @impl true
  def init(_init_arg) do
    children = [
      ConnectionSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
