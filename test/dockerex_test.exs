defmodule DockerexTest do
  use ExUnit.Case
  doctest Dockerex

  test "Docker Engine API version" do
    assert Dockerex.api_version() == "v1.37"
  end
end
