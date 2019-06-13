defmodule Dockerex.Containers.Types do
  defmacro __using__(_) do
    quote do
      alias Dockerex.Containers.Types.ListParams
      alias Dockerex.Containers.Types.ListResponse
      alias Dockerex.Containers.Types.ContainerResponse
    end
  end

  defmodule ListParams do
    @type t :: %{all: boolean(), limit: integer(), size: integer(), filters: %{}} | nil
  end

  defmodule ListResponse do
    @type t :: %{atom() => any()}
  end

  defmodule ContainerResponse do
    @type t :: %{atom() => any()}
  end
end
