defmodule DockerexTest do
  use ExUnit.Case
  doctest Dockerex

  test "Docker version" do
    assert Dockerex.docker_version() == "v1.37"
  end
end
