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
            HostConfig: %{atom() => String.t()},
            Id: String.t(),
            Image: String.t(),
            ImageID: String.t(),
            Labels: %{atom() => String.t()},
            Mounts: [
              %{
                Name: String.t(),
                Source: String.t(),
                Destination: String.t(),
                Driver: String.t(),
                Mode: String.t(),
                RW: boolean(),
                Propagation: String.t()
              }
            ],
            Names: [String.t()],
            NetworkSettings: %{
              Networks: %{
                bridge: %{
                  Aliases: String.t() | nil,
                  DriverOpts: String.t() | nil,
                  EndpointID: String.t(),
                  Gateway: String.t(),
                  GlobalIPv6Address: String.t(),
                  GlobalIPv6PrefixLen: integer(),
                  IPAMConfig: String.t() | nil,
                  IPAddress: String.t(),
                  IPPrefixLen: integer(),
                  IPv6Gateway: String.t(),
                  Links: String.t() | nil,
                  MacAddress: String.t(),
                  NetworkID: String.t()
                }
              }
            },
            Ports: [
              %{
                PrivatePort: integer(),
                PublicPort: integer(),
                Type: String.t()
              }
            ],
            State: String.t(),
            Status: String.t()
          }
  end
end
