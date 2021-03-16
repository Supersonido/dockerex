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

  If `pid` is a `t:pid/0` then the output is streamed to the process:

  - `{:status, status_code}` where `status_code` is the HTTP status code
  - `{:headers, headers}` where `headers` are the headers ot the HTTP response
  - `{:chunk, chunk}` where `chunk` is a `t:Dockerex.frame/0` or `t:binary/0`
  - `{:redirect, to}` where `to` is the URL of a redirection
  - `:end` to indicate the stream ended

  Note: This endpoint works only for containers with the json-file or journald logging driver.
  """
  @spec logs(String.t(), LogsParams.t(), pid() | nil) ::
          Dockerex.engine_ok() | Dockerex.engine_err()
  def logs(id, params \\ %{stdout: true}, pid \\ nil)

  def logs(id, params, nil) when is_map(params) do
    url =
      Dockerex.get_url(
        "/containers/#{id}/logs",
        Map.put(params, :follow, false)
      )

    # The decoder depends on configuration: :logs if TTY disabled
    decoder =
      case Dockerex.Containers.get(id) do
        {:ok, %{Config: %{Tty: false}}} ->
          :logs

        _ ->
          :raw
      end

    HTTPoison.get(url, %{}, [])
    |> Dockerex.process_httpoison_resp(decoder: decoder)
  end

  def logs(id, params, pid) when is_pid(pid) do
    url =
      Dockerex.get_url(
        "/containers/#{id}/logs",
        Map.put(params, :follow, true)
      )

    # The decoder depends on configuration: Dockered.decode_logs if TTY disabled
    decoder =
      case Dockerex.Containers.get(id) do
        {:ok, %{Config: %{Tty: false}}} ->
          &Dockerex.decode_logs/1

        _ ->
          nil
      end

    {:ok, listener} = Dockerex.Containers.Logs.Supervisor.start_child(pid, decoder)
    options = Dockerex.add_options(stream_to: listener)

    HTTPoison.get(url, %{}, options)
    |> Dockerex.process_httpoison_resp()
    |> case do
      {:error, _, _} = resp ->
        Dockerex.Containers.Logs.Supervisor.stop_child(listener)
        resp

      resp ->
        resp
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

  @doc """
  Send a POSIX signal to a container, defaulting to killing to the container.
  """
  @spec kill(String.t(), String.t() | nil) ::
          :ok | {:error, :not_running | :not_found | :request_error}
  def kill(id, signal \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/kill", %{signal: signal})
    options = Dockerex.add_options()

    HTTPoison.post(url, "", %{}, options)
    |> Dockerex.process_httpoison_resp(decoder: :raw)
    |> case do
      {:ok, ""} -> :ok
      resp -> resp
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
