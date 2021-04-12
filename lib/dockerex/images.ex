defmodule Dockerex.Images do
  @moduledoc """
  Module that interfaces the image related API of the Docker Engine
  API. See https://docs.docker.com/engine/api/ for more information.
  """

  use Dockerex.Images.Types
  require Logger

  # TODO(AH): adapt spec and implementation to Dockerex.process_httpoison_resp
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

  @doc """
  Return low-level information about an image.
  """
  @spec get(String.t()) :: {:ok, Image.t()} | Dockerex.engine_err()
  def get(id) do
    opts = Dockerex.add_options()

    HTTPoison.get(Dockerex.get_url("/images/#{id}/json"), opts)
    |> Dockerex.process_httpoison_resp()
  end

  @doc """
  Create an image by either pulling it from a registry or importing it.
  """
  @spec create(CreateParams.t(), binary() | nil) :: {:ok, [map()]} | Dockerex.engine_err()
  def create(params, image \\ nil) do
    url = Dockerex.get_url("/images/create", params)
    headers = Dockerex.add_auth()
    opts = Dockerex.add_options()

    HTTPoison.post(url, image || "", headers, opts)
    |> Dockerex.process_httpoison_resp(decoder: :progress)
  end

  @doc """
  Build an image from a tar archive with a Dockerfile in it.
  """
  @spec build(BuildParams.t(), binary() | nil, map()) ::
          {:ok, String.t(), [map()]}
          | {:error, :build_error, String.t() | map()}
          | Dockerex.engine_err()
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

    HTTPoison.post(url, image || "", headers, options)
    |> Dockerex.process_httpoison_resp(decoder: :progress)
    |> case do
      {:ok, progress} ->
        errors =
          for progress_line <- progress,
              Map.has_key?(progress_line, :errorDetail) or Map.has_key?(progress_line, :error) do
            progress_line
          end

        error = "Cannot extract image ID from #{inspect(progress)}"

        case errors do
          [] ->
            auxs =
              for progress_line <- progress,
                  Map.has_key?(progress_line, :aux) do
                progress_line[:aux]
              end

            case auxs do
              [%{ID: id} | _] ->
                {:ok, id, progress}

              _ ->
                Logger.error(error)
                {:error, :build_error, error}
            end

          [error1 | _errors] ->
            Logger.error(error)
            {:error, :build_error, error1}
        end

      response ->
        response
    end
  end

  # TODO(AH): adapt spec and implementation to Dockerex.process_httpoison_resp
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

  @doc """
  Remove an image, along with any untagged parent images that were referenced by that image.
  """
  @spec remove(String.t(), RemoveParams.t()) :: {:ok, RemoveResponse.t()} | Dockerex.engine_err()
  def remove(id, params \\ nil) do
    url = Dockerex.get_url("/images/#{id}", params)
    options = Dockerex.add_options()

    HTTPoison.delete(url, %{}, options)
    |> Dockerex.process_httpoison_resp()
  end
end
