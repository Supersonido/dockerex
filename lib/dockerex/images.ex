defmodule Dockerex.Images do
  use Dockerex.Images.Types
  require Logger

  @spec list(ListParams.t()) ::
          {:ok, [ImageAbstract.t()]} | {:error, :bad_request, map()} | {:error, :request_error}
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

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, :bad_request, Poison.decode!(body)}

      resp ->
        Logger.error(resp)
        {:error, :request_error}
    end
  end

  @spec get(String.t()) :: {:ok, Image.t()} | {:error, :not_found | :request_error}
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

  @spec create(CreateParams.t(), binary() | nil) ::
          {:ok, String.t()} | {:error, :bad_request, map()} | {:error, :request_error}
  def create(params, image \\ nil) do
    url = Dockerex.get_url("/images/create", params)
    headers = Dockerex.add_auth()

    case HTTPoison.post(url, image, headers, []) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, :bad_request, Poison.decode!(body)}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @spec build(CreateParams.t(), binary() | nil, map()) ::
          {:ok, String.t() | nil} | {:error, :bad_request, map()} | {:error, :request_error}
  def build(params, image \\ nil, registry_config \\ %{}) do
    url = Dockerex.get_url("/build", params)
    headers = Dockerex.add_registry_config(registry_config)

    case HTTPoison.post(url, image || "", headers, []) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        IO.inspect(body)

        info =
          String.split(body, "\r\n", trim: true)
          |> List.delete_at(-1)
          |> List.last()
          |> Poison.decode!()

        case info do
          %{"aux" => %{"ID" => id}} ->
            {:ok, id}

          _ ->
            {:ok, nil}
        end

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, :bad_request, Poison.decode!(body)}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @spec prune(map() | nil) :: {:ok, map()} | {:error, :request_error}
  def prune(params \\ nil) do
    params =
      case params do
        nil ->
          params

        _ ->
          filter = Map.get(params, :filters)
          Map.put(params, :filters, Poison.encode!(filter))
      end

    url = Dockerex.get_url("/images/prune", params)
    options = [timeout: :infinity, recv_timeout: :infinity]

    case HTTPoison.post(url, "", %{}, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 409}} ->
        {:error, :already_stopped}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end
end
