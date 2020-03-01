defmodule Dockerex.Containers.Types do
  defmacro __using__(_) do
    quote do
      alias Dockerex.Containers.Types.ListParams
      alias Dockerex.Containers.Types.ContainerAbstract
      alias Dockerex.Containers.Types.Container
      alias Dockerex.Containers.Types.CreateContainer
      alias Dockerex.Containers.Types.StartParams
      alias Dockerex.Containers.Types.StopParams
      alias Dockerex.Containers.Types.CreateContainerResponse
      alias Dockerex.Containers.Types.RemoveParams
      alias Dockerex.Containers.Types.PruneParams
      alias Dockerex.Containers.Types.PruneResponse
      alias Dockerex.Containers.Types.WaitResponse
      alias Dockerex.Containers.Types.GetArchiveParams
      alias Dockerex.Containers.Types.PutArchiveParams
    end
  end

  # ===================================================== #
  # Basic types (Required for Dockerex.Containers types)  #
  # ===================================================== #

  defmodule Mount do
    @type t :: %{
            Name: String.t(),
            Source: String.t(),
            Destination: String.t(),
            Driver: String.t(),
            Mode: String.t(),
            RW: boolean(),
            Propagation: String.t()
          }
  end

  defmodule Network do
    @type t :: %{
            Aliases: [String.t()] | nil,
            DriverOpts: %{Dockerex.Key.t() => String.t()} | nil,
            EndpointID: String.t(),
            Gateway: String.t(),
            GlobalIPv6Address: String.t(),
            GlobalIPv6PrefixLen: integer(),
            IPAMConfig:
              nil
              | %{
                  IPv4Address: String.t(),
                  IPv6Address: String.t(),
                  LinkLocalIPs: [String.t()]
                },
            IPAddress: String.t(),
            IPPrefixLen: integer(),
            IPv6Gateway: String.t(),
            Links: [String.t()] | nil,
            MacAddress: String.t(),
            NetworkID: String.t()
          }
  end

  defmodule Port do
    @type t :: %{
            PrivatePort: integer(),
            PublicPort: integer(),
            Type: String.t()
          }
  end

  defmodule Labels do
    @type t :: %{Dockerex.Key.t() => term()}
  end

  defmodule Volumes do
    @type t :: %{String.t() => map()}
  end

  defmodule Config do
    @type t :: %{
            AttachStderr: boolean(),
            AttachStdin: boolean(),
            AttachStdout: boolean(),
            Cmd: [String.t()],
            Domainname: String.t(),
            Env: [String.t()],
            Hostname: String.t(),
            Image: String.t(),
            Labels: Labels.t(),
            MacAddress: String.t(),
            NetworkDisabled: boolean(),
            OpenStdin: boolean(),
            StdinOnce: boolean(),
            Tty: boolean(),
            User: String.t(),
            Volumes: Volumes.t(),
            WorkingDir: String.t(),
            StopSignal: String.t(),
            StopTimeout: integer()
          }
  end

  defmodule PortBindings do
    @type t :: %{
            String.t() => [
              %{
                HostPort: String.t()
              }
            ]
          }
  end

  defmodule BlkioWeight do
    @type t :: %{Path: String.t(), Weight: integer()}
  end

  defmodule Device do
    @type t :: %{
            PathOnHost: String.t(),
            PathInContainer: String.t(),
            CgroupPermissions: String.t()
          }
  end

  defmodule Ulimits do
    @type t :: %{Name: String.t(), Soft: integer(), Hard: integer()}
  end

  defmodule Sysctls do
    @type t :: %{Dockerex.Key.t() => String.t()}
  end

  defmodule NetworkSettings do
    @type t :: %{
            Bridge: String.t(),
            SandboxID: String.t(),
            HairpinMode: boolean(),
            LinkLocalIPv6Address: String.t(),
            LinkLocalIPv6PrefixLen: integer(),
            SandboxKey: String.t(),
            EndpointID: String.t(),
            Gateway: String.t(),
            GlobalIPv6Address: String.t(),
            GlobalIPv6PrefixLen: integer(),
            IPAddress: String.t(),
            IPPrefixLen: integer(),
            IPv6Gateway: String.t(),
            MacAddress: String.t(),
            Networks: %{atom() => Network.t()}
          }
  end

  defmodule State do
    @type t :: %{
            Error: String.t(),
            ExitCode: integer(),
            FinishedAt: String.t(),
            OOMKilled: boolean(),
            Dead: boolean(),
            Paused: boolean(),
            Pid: integer(),
            Restarting: boolean(),
            Running: boolean(),
            StartedAt: String.t(),
            Status: String.t()
          }
  end

  defmodule NetworkingConfig do
    @type t :: %{
            EndpointsConfig: %{
              isolated_nw: %{
                IPAMConfig: %{
                  IPv4Address: String.t(),
                  IPv6Address: String.t(),
                  LinkLocalIPs: [String.t()]
                },
                Links: [String.t()],
                Aliases: [String.t()]
              }
            }
          }
  end

  defmodule HostConfig do
    @type t :: %{
            Binds: [String.t()],
            Links: [String.t()],
            MaximumIOps: integer(),
            MaximumIOBps: integer(),
            BlkioWeight: integer(),
            BlkioWeightDevice: [BlkioWeight.t()],
            BlkioDeviceReadBps: [BlkioWeight.t()],
            BlkioDeviceWriteBps: [BlkioWeight.t()],
            BlkioDeviceReadIOps: [BlkioWeight.t()],
            BlkioDeviceWriteIOps: [BlkioWeight.t()],
            ContainerIDFile: String.t(),
            CpusetCpus: String.t(),
            CpusetMems: String.t(),
            CpuPercent: integer(),
            CpuShares: integer(),
            CpuPeriod: integer(),
            CpuRealtimePeriod: integer(),
            CpuRealtimeRuntime: integer(),
            Devices: [Device.t()],
            IpcMode: String.t(),
            Memory: integer(),
            MemorySwap: integer(),
            MemoryReservation: integer(),
            KernelMemory: integer(),
            OomKillDisable: boolean(),
            OomScoreAdj: integer(),
            NetworkMode: String.t(),
            PidMode: String.t(),
            PortBindings: PortBindings.t(),
            Privileged: boolean(),
            ReadonlyRootfs: boolean(),
            PublishAllPorts: boolean(),
            RestartPolicy: %{
              MaximumRetryCount: integer(),
              Name: String.t()
            },
            LogConfig: %{
              Type: String.t(),
              Config: map()
            },
            Sysctls: Sysctls.t(),
            Ulimits: [Ulimits.t()],
            VolumeDriver: String.t(),
            ShmSize: integer(),
            NanoCPUs: integer(),
            CpuQuota: integer(),
            CpusetCpus: String.t(),
            CpusetMems: String.t(),
            MaximumIOps: integer(),
            MaximumIOBps: integer(),
            MemorySwappiness: integer(),
            PidsLimit: integer(),
            Dns: [String.t()],
            DnsOptions: [String.t()],
            DnsSearch: [String.t()],
            VolumesFrom: [String.t()],
            CapAdd: [String.t()],
            CapDrop: [String.t()],
            GroupAdd: [String.t()],
            AutoRemove: boolean(),
            NetworkMode: String.t(),
            Devices: [Device.t()],
            SecurityOpt: [String.t()],
            StorageOpt: %{size: String.t()},
            CgroupParent: String.t(),
            ShmSize: integer()
          }
  end

  # ============================== #
  # Types for Dockerex.Containers  #
  # ============================== #

  defmodule ContainerAbstract do
    @type t :: %{
            Command: String.t(),
            Created: integer(),
            HostConfig: %{atom() => String.t()},
            Id: String.t(),
            Image: String.t(),
            ImageID: String.t(),
            Labels: Labels.t(),
            Mounts: [Mount.t()],
            Names: [String.t()],
            NetworkSettings: %{Networks: %{atom() => Network.t()}},
            Ports: [Port.t()],
            State: String.t(),
            Status: String.t()
          }
  end

  defmodule Container do
    @type t :: %{
            AppArmorProfile: String.t(),
            Args: [String.t()],
            Config: Config.t(),
            Created: String.t(),
            Driver: String.t(),
            HostConfig: HostConfig.t(),
            HostnamePath: String.t(),
            HostsPath: String.t(),
            LogPath: String.t(),
            Id: String.t(),
            Image: String.t(),
            MountLabel: String.t(),
            Name: String.t(),
            NetworkSettings: NetworkSettings.t(),
            Path: String.t(),
            ProcessLabel: String.t(),
            ResolvConfPath: String.t(),
            RestartCount: integer(),
            State: State.t(),
            Mounts: [Mount.t()]
          }
  end

  defmodule CreateContainer do
    @type t :: %{
            optional(:Hostname) => String.t(),
            optional(:Domainname) => String.t(),
            optional(:User) => String.t(),
            optional(:AttachStdin) => boolean(),
            optional(:AttachStdout) => boolean(),
            optional(:AttachStderr) => boolean(),
            optional(:Tty) => boolean(),
            optional(:OpenStdin) => boolean(),
            optional(:StdinOnce) => boolean(),
            optional(:Env) => [String.t()],
            optional(:Cmd) => [String.t()],
            optional(:Entrypoint) => String.t(),
            required(:Image) => String.t(),
            optional(:Labels) => Labels.t(),
            optional(:Volumes) => Volumes.t(),
            optional(:WorkingDir) => String.t(),
            optional(:NetworkDisabled) => boolean(),
            optional(:MacAddress) => String.t(),
            optional(:ExposedPorts) => %{String.t() => map()},
            optional(:StopSignal) => String.t(),
            optional(:StopTimeout) => integer(),
            optional(:HostConfig) => HostConfig.t(),
            optional(:NetworkingConfig) => NetworkingConfig.t()
          }
  end

  defmodule CreateContainerResponse do
    @type t :: %{Id: String.t(), Warnings: nil | [String.t()]}
  end

  defmodule ListParamsFilter do
    @type t :: %{
            ancestor: [String.t()],
            before: [String.t()],
            expose: [String.t()],
            exited: [integer()],
            health: [:starting | :healthy | :unhealthy | :none],
            id: [String.t()],
            isolation: [:default | :process | :hyperv],
            "is-task": [boolean()],
            label: [String.t()],
            name: [String.t()],
            network: [String.t()],
            publish: [String.t()],
            since: [String.t()],
            status: [:created | :restarting | :running | :removing | :paused | :exited | :dead],
            volume: [String.t()]
          }
  end

  defmodule ListParams do
    @type t ::
            %{all: boolean(), limit: integer(), size: integer(), filters: ListParamsFilter.t()}
            | nil
  end

  defmodule StartParams do
    @type t :: %{detachKeys: String.t()}
  end

  defmodule StopParams do
    @type t :: %{t: integer()}
  end

  defmodule RemoveParams do
    @type t :: %{v: boolean(), force: boolean(), link: boolean()}
  end

  defmodule PruneParamsFilter do
    @type t :: %{until: [integer()], label: [String.t()]}
  end

  defmodule PruneParams do
    @type t :: %{filters: PruneParamsFilter.t()}
  end

  defmodule PruneResponse do
    @type t :: %{
            ContainersDeleted: [String.t()] | nil,
            SpaceReclaimed: integer()
          }
  end

  defmodule WaitResponse do
    @type t :: %{Error: [String.t()] | nil, StatusCode: 0}
  end

  defmodule GetArchiveParams do
    @type t :: %{path: String.t()}
  end

  defmodule PutArchiveParams do
    @type t :: %{
            required(:path) => String.t(),
            optional(:noOverwriteDirNonDir) => boolean(),
            optional(:copyUIDGID) => boolean()
          }
  end
end
