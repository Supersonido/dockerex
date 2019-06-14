defmodule Dockerex.Containers do
  use Dockerex.Containers.Types
  require Logger

  @spec list(ListParams.t()) ::
          {:ok, [ContainerAbstract.t()]} | {:error, :request_error | :bad_request}
  def list(options \\ nil) do
    case HTTPoison.get(Dockerex.get_url("/containers/json", options)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 400}} ->
        {:error, :bad_request}

      resp ->
        Logger.error(resp)
        {:error, :request_error}
    end
  end

  @spec inspect(String.t()) :: Container.t() | {:error, :request_error | :not_found}
  def inspect(id) do
    case HTTPoison.get(Dockerex.get_url("/containers/#{id}/json")) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error(resp)
        {:error, :request_error}
    end
  end

  @spec create(String.t(), map()) :: {:ok, map()} | {:error, :request_error | :not_found}
  def create(name, params) do
    url = Dockerex.get_url("/containers/create", %{name: name})

    case HTTPoison.post(url, params, %{}, []) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error(resp)
        {:error, :request_error}
    end
  end

  @spec logs(String.t(), pid() | nil, map()) :: String.t() | {:error, :not_found | :request_error}
  def logs(id, nil, params) do
    url = Dockerex.get_url("/containers/#{id}/logs", params)

    case HTTPoison.get(url, %{}, []) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        body

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      resp ->
        Logger.error(resp)
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
        Logger.error(resp)
        {:error, :request_error}
    end
  end
end
