defmodule Dockerex.Containers.Types do
  defmacro __using__(_) do
    quote do
      alias Dockerex.Containers.Types.ListParams
      alias Dockerex.Containers.Types.ListResponse
    end
  end

  defmodule ListParams do
    @type t :: %{all: boolean(), limit: integer(), size: integer(), filters: %{}} | nil
  end

  defmodule ListResponse do
    @type t :: %{
            Command: String.t(),
            Created: integer(),
            HostConfig: %{NetworkMode: "default"} | %{},
            Id: String.t(),
            Image: String.t(),
            ImageID: "sha256:fce289e99eb9bca977dae136fbe2a82b6b7d4c372474c9235adc1741675f587e",
            Labels: %{},
            Mounts: [],
            Names: [String.t()],
            NetworkSettings: %{
              Networks: %{
                bridge: %{
                  Aliases: nil,
                  DriverOpts: nil,
                  EndpointID: "",
                  Gateway: "",
                  GlobalIPv6Address: "",
                  GlobalIPv6PrefixLen: 0,
                  IPAMConfig: nil,
                  IPAddress: "",
                  IPPrefixLen: 0,
                  IPv6Gateway: "",
                  Links: nil,
                  MacAddress: "",
                  NetworkID: "800b2e1a52cebb65aad6948cb19542f8cf88701ed48664eda8e16695526ac2ee"
                }
              }
            },
            Ports: [],
            State: "exited",
            Status: "Exited (0) 11 minutes ago"
          }
  end
end
