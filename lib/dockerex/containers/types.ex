defmodule Dockerex.Containers.Types do
  defmacro __using__(_) do
    quote do
      alias Dockerex.Containers.Types.ListParams
      alias Dockerex.Containers.Types.ListResponse
      alias Dockerex.Containers.Types.ContainerResponse
    end
  end

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

  defmodule Volumes do
    @type t :: %{String.t() => map()}
  end

  defmodule HostConfig do
    @type t :: %{
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
            PortBindings: %{},
            Privileged: boolean(),
            ReadonlyRootfs: boolean(),
            PublishAllPorts: boolean(),
            RestartPolicy: %{
              MaximumRetryCount: integer(),
              Name: String.t()
            },
            LogConfig: %{
              Type: String.t()
            },
            Sysctls: Sysctls.t(),
            Ulimits: [Ulimits.t()],
            VolumeDriver: String.t(),
            ShmSize: integer()
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

  defmodule ListParams do
    @type t :: %{all: boolean(), limit: integer(), size: integer(), filters: %{}} | nil
  end
end
