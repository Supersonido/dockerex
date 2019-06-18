defmodule Dockerex.Containers do
  require Logger
  use Dockerex.Containers.Types

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

  @spec get(String.t()) :: {:ok, Container.t()} | {:error, :request_error | :not_found}
  def get(id) do
    case HTTPoison.get(Dockerex.get_url("/containers/#{id}/json")) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @spec create(String.t() | nil, CreateContainer.t()) ::
          {:ok, CreateContainerResponse.t()} | {:error, :request_error | :not_found}
  def create(name, params) do
    url = Dockerex.get_url("/containers/create", %{name: name})
    headers = Dockerex.headers()

    case HTTPoison.post(url, Poison.encode!(params), headers, []) do
      {:ok, %HTTPoison.Response{body: body, status_code: 201}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, :bad_request, Poison.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: 409}} ->
        {:error, :conflict}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @spec logs(String.t(), pid() | nil, map()) ::
          {:ok, binary()} | {:error, :not_found | :request_error}
  def logs(id, nil, params) do
    url = Dockerex.get_url("/containers/#{id}/logs", params)

    case HTTPoison.get(url, %{}, []) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  def logs(id, pid, params) do
    url = Dockerex.get_url("/containers/#{id}/logs", Map.put(params, :follow, true))
    {:ok, gen} = Dockerex.Containers.Logs.Supervisor.start_child(pid)
    options = [stream_to: gen, timeout: :infinity, recv_timeout: :infinity]

    case HTTPoison.get(url, %{}, options) do
      {:ok, %HTTPoison.AsyncResponse{id: reference}} ->
        {:ok, reference}

      resp ->
        GenServer.stop(gen)
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @spec start(String.t(), StartParams.t() | nil) ::
          {:ok, String.t()} | {:error, :already_started | :not_found | :request_error}
  def start(id, params \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/start", params)
    options = [timeout: :infinity, recv_timeout: :infinity]

    case HTTPoison.post(url, "", %{}, options) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok, id}

      {:ok, %HTTPoison.Response{status_code: 304}} ->
        {:error, :already_started}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @spec stop(String.t(), StopParams.t() | nil) ::
          {:ok, String.t()} | {:error, :already_stopped | :not_found | :request_error}
  def stop(id, params \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/stop", params)
    options = [timeout: :infinity, recv_timeout: :infinity]

    case HTTPoison.post(url, "", %{}, options) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok, id}

      {:ok, %HTTPoison.Response{status_code: 304}} ->
        {:error, :already_stopped}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

  @spec kill(String.t(), String.t() | nil) ::
          :ok | {:error, :not_running | :not_found | :request_error}
  def kill(id, signal \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/kill", %{signal: signal})
    options = [timeout: :infinity, recv_timeout: :infinity]

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

  @spec remove(String.t(), RemoveParams.t() | nil) ::
          :ok | {:error, :running | :not_found | :request_error}
  def remove(id, params \\ nil) do
    url = Dockerex.get_url("/containers/#{id}", params)
    options = [timeout: :infinity, recv_timeout: :infinity]

    case HTTPoison.delete(url, %{}, options) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        :ok

      {:ok, %HTTPoison.Response{status_code: 409}} ->
        {:error, :running}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end

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

  @spec wait(String.t(), String.t() | nil) ::
          {:ok, WaitResponse.t()} | {:error, :request_error | :not_found}
  def wait(id, condition \\ nil) do
    url = Dockerex.get_url("/containers/#{id}/wait", %{condition: condition})
    options = [timeout: :infinity, recv_timeout: :infinity]

    case HTTPoison.post(url, "", %{}, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error("#{inspect(resp)}")
        {:error, :request_error}
    end
  end
end
