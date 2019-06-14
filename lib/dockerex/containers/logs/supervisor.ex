defmodule Dockerex.Containers.Logs.Supervisor do
  use DynamicSupervisor
  alias Dockerex.Containers.Logs.Worker

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(pid) do
    spec = %{id: Worker, start: {Worker, :start_link, [pid]}, restart: :transient}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 0,
      extra_arguments: []
    )
  end
end
