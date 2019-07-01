defmodule Dockerex do
  @version "v1.37"

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
end
