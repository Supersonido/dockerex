defmodule Dockerex.Containers do
  use Dockerex.Containers.Types
  require Logger

  @spec list(map() | nil) :: [ListResponse.t()]
  def list(options \\ nil) do
    case HTTPoison.get(Dockerex.get_url("/containers/json", options)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        Poison.decode!(body, keys: :atoms)

      resp ->
        Logger.error(resp)
        {:error, :request_error}
    end
  end
end
