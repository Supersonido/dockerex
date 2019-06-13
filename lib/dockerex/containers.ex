defmodule Dockerex.Containers do
  use Dockerex.Containers.Types
  require Logger

  @spec list(ListParams.t()) :: [ListResponse.t()] | {:error, :request_error}
  def list(options \\ nil) do
    case HTTPoison.get(Dockerex.get_url("/containers/json", options)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        Poison.decode!(body, keys: :atoms)

      resp ->
        Logger.error(resp)
        {:error, :request_error}
    end
  end

  @spec inspect(String.t()) :: ContainerResponse.t() | {:error, :request_error | :not_found}
  def inspect(id) do
    case HTTPoison.get(Dockerex.get_url("/containers/#{id}/json")) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        Poison.decode!(body, keys: :atoms)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error(resp)
        {:error, :request_error}
    end
  end
end
