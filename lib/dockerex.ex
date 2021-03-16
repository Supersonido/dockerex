defmodule Dockerex do
  require Logger

  @version "v1.37"
  @progress_keys [:stream, :error, :errorDetail, :status, :aux]

  @type engine_ok() ::
          {:ok, map() | [map()]}

  @type http_const() ::
          :not_modified
          | :bad_request
          | :not_found
          | :forbidden
          | :conflict
          | :internal_server_error

  @type engine_err() :: {:error, http_const() | :request_error, map() | nil}

  @type httpoison_resp() ::
          {:ok,
           HTTPoison.Response.t()
           | HTTPoison.AsyncResponse.t()
           | HTTPoison.MaybeRedirect.t()}
          | {:error, HTTPoison.Error.t()}

  @doc """
  Returns the docker version the library is using.

  ## Examples

  iex> Dockerex.api_version()
  "v1.37"

  """
  def api_version(), do: @version

  @doc """
  For some endpoints, the response contains a progress
  information. This function process the response and returns a keywords structure.

  ## Examples

  iex> Dockerex.decode_progress("")
  []

  iex> Dockerex.decode_progress("{\\"stream\\":\\"Hola\\"}")
  [%{stream: "Hola"}]

  iex> Dockerex.decode_progress("{\\"stream\\":\\"Step 1/1 : FROM ubuntu:20.04\\"}\\r\\n{\\"status\\":\\"Pulling from library/ubuntu\\",\\"id\\":\\"20.04\\"}\\r\\n{\\"stream\\":\\"\\\\n\\"}\\r\\n{\\"stream\\":\\" ---\\\\u003e 4dd97cefde62\\\\n\\"}\\r\\n{\\"aux\\":{\\"ID\\":\\"sha256:4dd97cefde62cf2d6bcfd8f2c0300a24fbcddbe0ebcd577cc8b420c29106869a\\"}}\\r\\n{\\"stream\\":\\"Successfully built 4dd97cefde62\\\\n\\"}\\r\\n")
  [
    %{stream: "Step 1/1 : FROM ubuntu:20.04"},
    %{status: "Pulling from library/ubuntu", id: "20.04"},
    %{stream: "\n"},
    %{stream: " ---> 4dd97cefde62\n"},
    %{aux: %{ID: "sha256:4dd97cefde62cf2d6bcfd8f2c0300a24fbcddbe0ebcd577cc8b420c29106869a"}},
    %{stream: "Successfully built 4dd97cefde62\n"}
  ]
  """
  @spec decode_progress(body :: String.t()) :: [Poison.Decoder.t()]
  def decode_progress(body) do
    for line <- String.split(body, "\r\n", trim: true) do
      progress_line = Poison.decode!(line, keys: :atoms)

      if is_map(progress_line) do
        valid_keys =
          for key <- @progress_keys,
              Map.has_key?(progress_line, key) do
            key
          end

        if valid_keys == [] do
          "No valid key found in #{inspect(line)}"
          |> Logger.error()
        end
      else
        "No json object found: #{inspect(line)}"
        |> Logger.error()
      end

      progress_line
    end
  end

  @spec get_url(String.t(), map() | nil) :: String.t()
  def get_url(endpoint \\ "", query \\ nil) do
    conf = Application.get_env(:dockerex, :url, "http://127.0.0.1:2375/")
    entrypoint = URI.merge(URI.parse(conf), @version)
    uri = URI.merge(entrypoint, endpoint)

    uri =
      case query do
        nil ->
          uri

        _ ->
          URI.merge(uri, "?" <> URI.encode_query(query))
      end

    URI.to_string(uri)
  end

  @spec headers(map()) :: map()
  def headers(headers \\ %{}) do
    %{"Content-Type" => "application/json"} |> Map.merge(headers)
  end

  @spec add_auth(map()) :: map()
  def add_auth(headers \\ %{}) do
    case Application.get_env(:dockerex, :identitytoken) do
      nil ->
        headers

      token ->
        token64 = Poison.encode!(token) |> Base.encode64()
        Map.put(headers, "X-Registry-Auth", token64)
    end
  end

  @spec add_registry_config(map(), map()) :: map()
  def add_registry_config(registry_config, headers \\ %{}) do
    registry64 = Poison.encode!(registry_config) |> Base.encode64()
    Map.put(headers, "X-Registry-Config", registry64)
  end

  @spec add_options(Keyword.t()) :: Keyword.t()
  def add_options(ops \\ []) do
    Keyword.merge(ops, timeout: :infinity, recv_timeout: :infinity)
  end

  defmodule Key do
    @type t :: atom() | String.t()
  end

  @doc """
  Processes HTTPoison responses. If opts[:progress] is not falsy,
  response body is assume to be of type "progress", like

        {"stream":"Step 1/1 : FROM ubuntu:20.04"}\r
        {"status":"Pulling from library/ubuntu","id":"20.04"}\r
        ...

  Returns a data that is close to Docker Engine API responses.
  """
  @spec process_httpoison_resp(httpoison_resp(), Keyword.t()) :: engine_ok() | engine_err()
  def process_httpoison_resp(response, opts \\ nil) do
    opts = opts || []

    case response do
      {:ok, %HTTPoison.Response{status_code: code, body: body}} when 200 <= code and code < 300 ->
        decoded =
          case opts[:decoder] do
            :raw ->
              body

            :progress ->
              decode_progress(body)

            other when other == nil or other == :json ->
              Poison.decode!(body, keys: :atoms)
          end

        {:ok, decoded}

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        decoded = Poison.decode!(body, keys: :atoms)

        error =
          case code do
            304 -> :not_modified
            400 -> :bad_request
            403 -> :forbidden
            404 -> :not_found
            409 -> :conflict
            500 -> :internal_server_error
          end

        {:error, error, decoded}

      {:error, %HTTPoison.Error{id: _id, reason: reason}} ->
        Logger.error("HTTP Client Error: #{inspect(reason)}")

        {:error, :request_error,
         %{
           reason:
             if is_binary(reason) do
               reason
             else
               inspect(reason)
             end
         }}
    end
  end
end
