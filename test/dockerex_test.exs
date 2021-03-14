defmodule DockerexTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Dockerex.Images

  test "Docker Engine API version" do
    assert Dockerex.api_version() == "v1.37"
  end

  test "Decode progress" do
    decoded_progress =
      """
      {"stream":"Step 1/1 : FROM ubuntu:20.04"}\r
      {"status":"Pulling from library/ubuntu","id":"20.04"}\r
      {"stream":"\\n"}\r
      {"stream":" ---\\u003e 4dd97cefde62\\n"}\r
      {"aux":{"ID":"sha256:4dd97cefde62cf2d6bcfd8f2c0300a24fbcddbe0ebcd577cc8b420c29106869a"}}\r
      {"stream":"Successfully built 4dd97cefde62\\n"}\r
      """
      |> Dockerex.decode_progress()

    assert [
             %{stream: "Step 1/1 : FROM ubuntu:20.04"},
             %{status: "Pulling from library/ubuntu", id: "20.04"},
             %{stream: "\n"},
             %{stream: " ---> 4dd97cefde62\n"},
             %{
               aux: %{
                 ID: "sha256:4dd97cefde62cf2d6bcfd8f2c0300a24fbcddbe0ebcd577cc8b420c29106869a"
               }
             },
             %{stream: "Successfully built 4dd97cefde62\n"}
           ] ==
             decoded_progress
  end

  test "Decode progress with errors" do
    decode_progress_with_errors = fn ->
      decoded_progress =
        """
        {"stream":"Step 1/1 : FROM ubuntu:20.04"}\r
        {"status":"Pulling from library/ubuntu","id":"20.04"}\r
        {"stream":"\\n"}\r
        {"stream":" ---\\u003e 4dd97cefde62\\n"}\r
        {"non_valid_key":"Data for non_valid_key"}\r
        {"aux":{"ID":"sha256:4dd97cefde62cf2d6bcfd8f2c0300a24fbcddbe0ebcd577cc8b420c29106869a"}}\r
        {"stream":"Successfully built 4dd97cefde62\\n"}\r
        {"status":"Spureous status", "stream":"Successfully built 4dd97cefde62\\n"}\r
        """
        |> Dockerex.decode_progress()

      assert [
               %{stream: "Step 1/1 : FROM ubuntu:20.04"},
               %{status: "Pulling from library/ubuntu", id: "20.04"},
               %{stream: "\n"},
               %{stream: " ---> 4dd97cefde62\n"},
               %{non_valid_key: "Data for non_valid_key"},
               %{
                 aux: %{
                   ID: "sha256:4dd97cefde62cf2d6bcfd8f2c0300a24fbcddbe0ebcd577cc8b420c29106869a"
                 }
               },
               %{stream: "Successfully built 4dd97cefde62\n"},
               %{status: "Spureous status", stream: "Successfully built 4dd97cefde62\n"}
             ] == decoded_progress
    end

    assert capture_log(decode_progress_with_errors) =~ "No valid key found"
  end

  test "Container built from Dockerfile" do
    tmp_dirname = "/tmp/dockerex"

    assert is_list(File.rm_rf!(tmp_dirname))
    assert :ok == File.mkdir_p!(tmp_dirname)

    dockerfile = """
    FROM ubuntu:17.04
    """

    dockerfile_filename = Path.join([tmp_dirname, "Dockerfile"])

    tar_filename = Path.join([tmp_dirname, "dockerex.tar"])

    assert :ok == File.write!(Path.join([tmp_dirname, "Dockerfile"]), dockerfile)

    assert :ok ==
             :erl_tar.create(tar_filename, [
               {String.to_charlist("Dockerfile"), String.to_charlist(dockerfile_filename)}
             ])

    assert {:ok, stream} = File.read(tar_filename)

    assert {:ok, "sha256:" <> _id, _body} = Images.build(%{}, stream)
  end

  test "Container built from Dockerfile with syntax errors" do
    tmp_dirname = "/tmp/dockerex"

    assert is_list(File.rm_rf!(tmp_dirname))
    assert :ok == File.mkdir_p!(tmp_dirname)

    dockerfile = """
    FRO ubuntu:17.04
    """

    dockerfile_filename = Path.join([tmp_dirname, "Dockerfile"])

    tar_filename = Path.join([tmp_dirname, "dockerex.tar"])

    assert :ok == File.write!(Path.join([tmp_dirname, "Dockerfile"]), dockerfile)

    assert :ok ==
             :erl_tar.create(tar_filename, [
               {String.to_charlist("Dockerfile"), String.to_charlist(dockerfile_filename)}
             ])

    assert {:ok, stream} = File.read(tar_filename)

    assert {:error, :bad_request,
            %{message: "dockerfile parse error line 1: unknown instruction: FRO"}} ==
             Images.build(%{}, stream)
  end

  test "Container built from Dockerfile with semantic errors" do
    tmp_dirname = "/tmp/dockerex"

    assert is_list(File.rm_rf!(tmp_dirname))
    assert :ok == File.mkdir_p!(tmp_dirname)

    dockerfile = """
    FROM ubuntu:17
    """

    dockerfile_filename = Path.join([tmp_dirname, "Dockerfile"])

    tar_filename = Path.join([tmp_dirname, "dockerex.tar"])

    assert :ok == File.write!(Path.join([tmp_dirname, "Dockerfile"]), dockerfile)

    assert :ok ==
             :erl_tar.create(tar_filename, [
               {String.to_charlist("Dockerfile"), String.to_charlist(dockerfile_filename)}
             ])

    assert {:ok, stream} = File.read(tar_filename)

    assert {:error, :build_error,
            %{
              error: "manifest for ubuntu:17 not found: manifest unknown: manifest unknown",
              errorDetail: %{
                message: "manifest for ubuntu:17 not found: manifest unknown: manifest unknown"
              }
            }} ==
             Images.build(%{}, stream)
  end
end
