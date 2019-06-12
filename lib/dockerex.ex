defmodule Dockerex do
  @spec get_url(String.t(), map()) :: String.t()
  def get_url(endpoint \\ "", query \\ nil) do
    entrypoint = Application.get_env(:dockerex, :url, "http://127.0.0.1:2375/")
    uri = URI.merge(URI.parse(entrypoint), endpoint)

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
