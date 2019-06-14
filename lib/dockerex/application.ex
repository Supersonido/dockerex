defmodule Dockerex.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start timers supervisor
      supervisor(Dockerex.Containers.Logs.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Dockerex.Application]

    case Supervisor.start_link(children, opts) do
      {:ok, _} = ok ->
        ok

      error ->
        error
    end
  end
end
