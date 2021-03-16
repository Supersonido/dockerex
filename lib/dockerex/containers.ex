defmodule Dockerex.Containers do
  @moduledoc """
  Module that interfaces the containers related API of the Docker Engine
  API. See https://docs.docker.com/engine/api/ for more information.
  """

  require Logger
  use Dockerex.Containers.Types

  # TODO(AH): adapt spec and implementation to Dockerex.process_httpoison_resp
  @spec list(ListParams.t() | nil) ::
          {:ok, [ContainerAbstract.t()]} | {:error, :request_error | :bad_request}
  def list(options \\ nil) do
    options =
      case options do
        nil ->
          options

        _ ->
          filter = Map.get(options, :filters)
          Map.put(options, :filters, Poison.encode!(filter))
      end

    case HTTPoison.get(Dockerex.get_url("/containers/json", options)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, :bad_request, Poison.decode!(body)}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @doc """
  Return low-level information about a container.
  """
  @spec get(String.t()) :: {:ok, Container.t()} | Dockerex.engine_err()
  def get(id) do
    HTTPoison.get(Dockerex.get_url("/containers/#{id}/json"))
    |> Dockerex.process_httpoison_resp()
  end

  @doc """
  Create a container.
  """
  @spec create(String.t() | nil, CreateContainer.t()) ::
          {:ok, CreateContainerResponse.t()} | Dockerex.engine_err()
  def create(name \\ nil, params) do
    url = Dockerex.get_url("/containers/create", %{name: name})
    headers = Dockerex.headers()

    HTTPoison.post(url, Poison.encode!(params), headers, [])
    |> Dockerex.process_httpoison_resp()
  end

  @doc """
  Get stdout and stderr logs from a container.

  Note: This endpoint works only for containers with the json-file or journald logging driver.
  """
  @spec logs(String.t(), pid() | nil, LogsParams.t()) ::
          {:ok, binary()} | {:error, :not_found | :request_error}
  def logs(id, pid \\ nil, params \\ %{stdout: true, stderr: true})

  def logs(id, nil, params) do
    url = Dockerex.get_url("/containers/#{id}/logs", params)

    HTTPoison.get(url, %{}, [])
    |> Dockerex.process_httpoison_resp(decoder: :logs)
  end

  def logs(id, pid, params) do
    url = Dockerex.get_url("/containers/#{id}/logs", Map.put(params, :follow, true))
    {:ok, gen} = Dockerex.Containers.Logs.Supervisor.start_child(pid)
    options = Dockerex.add_options(stream_to: gen)

    case HTTPoison.get(url, %{}, options) do
      {:ok, %HTTPoison.AsyncResponse{id: reference}} ->
        {:ok, reference}

      resp ->
        GenServer.stop(gen)
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @doc """
  Start a container.
  """
  @spec start(String.t(), StartParams.t() | nil) :: :ok | Dockerex.engine_err()
  def start(id, params \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/start", params)
    options = Dockerex.add_options()

    HTTPoison.post(url, "", %{}, options)
    |> Dockerex.process_httpoison_resp(decoder: :raw)
    |> case do
      {:ok, ""} -> :ok
      resp -> resp
    end
  end

  @doc """
  Stop a container.
  """
  @spec stop(String.t(), StopParams.t() | nil) :: :ok | Dockerex.engine_err()
  def stop(id, params \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/stop", params)
    options = Dockerex.add_options()

    HTTPoison.post(url, "", %{}, options)
    |> Dockerex.process_httpoison_resp(decoder: :raw)
    |> case do
      {:ok, ""} -> :ok
      resp -> resp
    end
  end

  # TODO(AH): adapt spec and implementation to Dockerex.process_httpoison_resp
  @spec kill(String.t(), String.t() | nil) ::
          :ok | {:error, :not_running | :not_found | :request_error}
  def kill(id, signal \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/kill", %{signal: signal})
    options = Dockerex.add_options()

    case HTTPoison.post(url, "", %{}, options) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok, id}

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
  Remove a container.
  """
  @spec remove(String.t(), RemoveParams.t() | nil) :: :ok | Dockerex.engine_err()
  def remove(id, params \\ nil) do
    url = Dockerex.get_url("/containers/#{id}", params)
    options = Dockerex.add_options()

    HTTPoison.delete(url, %{}, options)
    |> Dockerex.process_httpoison_resp(decoder: :raw)
    |> case do
      {:ok, ""} -> :ok
      response -> response
    end
  end

  # TODO(AH): adapt spec and implementation to Dockerex.process_httpoison_resp
  @spec prune(PruneParams.t() | nil) :: {:ok, PruneResponse.t()} | {:error, :request_error}
  def prune(params \\ nil) do
    params =
      case params do
        nil ->
          params

        _ ->
          filter = Map.get(params, :filters)
          Map.put(params, :filters, Poison.encode!(filter))
      end

    url = Dockerex.get_url("/containers/prune", params)
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
  Block until a container stops, then returns the exit code.
  """
  @spec wait(String.t(), String.t() | nil) :: {:ok, WaitResponse.t()} | Dockerex.engine_err()
  def wait(id, condition \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/wait", %{condition: condition})
    options = Dockerex.add_options()

    HTTPoison.post(url, "", %{}, options)
    |> Dockerex.process_httpoison_resp()
  end

  @doc """
  Get a tar archive of a resource in the filesystem of container id.
  """
  @spec get_archive(String.t(), GetArchiveParams.t()) ::
          {:ok, binary()} | Dockerex.engine_err()
  def get_archive(id, params) do
    url = Dockerex.get_url("/containers/#{id}/archive", params)
    headers = Dockerex.headers()
    options = Dockerex.add_options()

    HTTPoison.get(url, headers, options)
    |> Dockerex.process_httpoison_resp(decoder: :raw)
  end

  @doc """
  Upload a tar archive to be extracted to a path in the filesystem of container id.
  """
  @spec put_archive(String.t(), binary(), PutArchiveParams.t()) ::
          :ok | Dockerex.engine_err()
  def put_archive(id, body, params) do
    url = Dockerex.get_url("/containers/#{id}/archive", params)
    headers = Dockerex.headers()
    options = Dockerex.add_options()

    HTTPoison.put(url, body, headers, options)
    |> Dockerex.process_httpoison_resp(decoder: :raw)
    |> case do
      {:ok, ""} -> :ok
      resp -> resp
    end
  end
end
