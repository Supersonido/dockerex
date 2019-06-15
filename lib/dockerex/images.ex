defmodule Dockerex.Images do
  use Dockerex.Images.Types
  require Logger

  @spec list(ListParams.t()) ::
          {:ok, [ImageAbstract.t()]} | {:error, :request_error | :bad_request}
  def list(options \\ nil) do
    options =
      case options do
        nil ->
          options

        _ ->
          filter = Map.get(options, :filters)
          Map.put(options, :filters, Poison.encode!(filter))
      end

    case HTTPoison.get(Dockerex.get_url("/images/json", options)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 400}} ->
        {:error, :bad_request}

      resp ->
        Logger.error(resp)
        {:error, :request_error}
    end
  end

  @spec get(String.t()) :: {:ok, Image.t()} | {:error, :request_error | :not_found}
  def get(id) do
    case HTTPoison.get(Dockerex.get_url("/images/#{id}/json")) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end
end
