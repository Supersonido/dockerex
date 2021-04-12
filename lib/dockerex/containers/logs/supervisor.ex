defmodule Dockerex.Containers.Logs.Supervisor do
  @moduledoc false

  use DynamicSupervisor
  alias Dockerex.Containers.Logs.Worker

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(listener, chunk_decoder \\ nil) when is_pid(listener) do
    spec = %{
      id: Worker,
      start: {Worker, :start_link, [listener, chunk_decoder]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
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
