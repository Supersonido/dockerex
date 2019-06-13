defmodule Dockerex do
  @version "v1.37"

  @spec get_url(String.t(), map()) :: String.t()
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
end
