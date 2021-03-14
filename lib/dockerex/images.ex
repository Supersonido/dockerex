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
          {:ok, String.t()}
          | {:error, :bad_request | :not_found, map()}
          | {:error, :request_error}
  def create(params, image \\ nil) do
    url = Dockerex.get_url("/images/create", params)
    headers = Dockerex.add_auth()

    case HTTPoison.post(url, image || "", headers, []) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, :bad_request, Poison.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        {:error, :not_found, Poison.decode!(body)}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @spec build(BuildParams.t(), binary() | nil, map()) ::
          {:ok, String.t() | nil, String.t()}
          | {:error, :bad_request, map()}
          | {:error, :request_error}
          | {:error, :build_error, BuildError.t()}

  def build(params, image \\ nil, registry_config \\ %{}) do
    params =
      case Map.get(params, :cachefrom, nil) do
        nil ->
          params

        cf ->
          Map.put(params, :cachefrom, Poison.encode!(cf))
      end

    params =
      case Map.get(params, :buildargs, nil) do
        nil ->
          params

        ba ->
          Map.put(params, :buildargs, Poison.encode!(ba))
      end

    params =
      case Map.get(params, :labels, nil) do
        nil ->
          params

        l ->
          Map.put(params, :labels, Poison.encode!(l))
      end

    url = Dockerex.get_url("/build", params)
    headers = Dockerex.add_registry_config(registry_config)
    options = Dockerex.add_options()

    case HTTPoison.post(url, image || "", headers, options) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        progress = Dockerex.decode_progress(body)

        errors =
          for progress_line <- progress,
              Map.has_key?(progress_line, :errorDetail) or Map.has_key?(progress_line, :error) do
            progress_line
          end

        case errors do
          [] ->
            error = "Cannot extract image ID from digest in #{inspect(body)}"

            auxs =
              for progress_line <- progress,
                  Map.has_key?(progress_line, :aux) do
                progress_line[:aux]
              end

            case auxs do
              [%{ID: id} | _] ->
                {:ok, id, body}

              _ ->
                Logger.error(error)
                {:error, :build_error, error}
            end

          [error1 | _errors] ->
            {:error, :build_error, error1}
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
    options = Dockerex.add_options()

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

  @spec remove(String.t(), RemoveParams.t()) ::
          {:ok, RemoveResponse.t()} | {:error, :conflict | :not_found | :request_error}
  def remove(id, params \\ nil) do
    url = Dockerex.get_url("/images/#{id}", params)
    options = Dockerex.add_options()

    case HTTPoison.delete(url, %{}, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 409}} ->
        {:error, :conflict}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end
end
