defmodule DockerexTest do
  use ExUnit.Case
  doctest Dockerex

  test "greets the world" do
    assert Dockerex.hello() == :world
  end
end
