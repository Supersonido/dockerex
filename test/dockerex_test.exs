defmodule DockerexTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Dockerex.Images
  alias Dockerex.Containers

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

  test "Image built from Dockerfile" do
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

  test "Image built from Dockerfile with syntax errors" do
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

  test "Image built from Dockerfile with semantic errors" do
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

  test "Image: create, get, and remove" do
    assert {:ok, _progress} = Images.create(fromImage: "ubuntu:18.04")

    assert {:ok, %{RepoTags: ["ubuntu:18.04"]}} = Images.get("ubuntu:18.04")

    assert {:ok, [%{Untagged: "ubuntu:18.04"} | _]} =
             Images.remove("ubuntu:18.04", %{force: true, noprune: true})

    assert {:error, :not_found, %{message: _message}} = Images.get("ubuntu:18.04")
  end

  test "Image creation error" do
    image = "non_existent_image_in_registry"
    assert {:error, :not_found, %{message: message}} = Images.create(fromImage: image)
    assert message =~ image
  end

  test "Image: get non existent image" do
    image = "non_existent_image_in_registry"
    assert {:error, :not_found, %{message: message}} = Images.get(image)
    assert message =~ image
  end

  test "Image: remove non existent image" do
    image = "non_existent_image_in_registry"
    assert {:error, :not_found, %{message: message}} = Images.remove(image)
    assert message =~ image
  end

  test "Create and remove a container and " do
    assert {:ok, _progress} = Images.create(fromImage: "ubuntu:18.04")
    assert {:ok, %{Id: id}} = Containers.create(nil, %{image: "ubuntu:18.04"})
    assert {:ok, %{Id: ^id}} = Containers.get(id)
    assert :ok == Containers.remove(id)
  end

  test "Get and remove non existent container" do
    id = "non_existent_container"
    assert {:error, :not_found, %{message: _}} = Containers.get(id)
    assert {:error, :not_found, %{message: _}} = Containers.remove(id)
  end

  test "Get archive" do
    assert {:ok, _progress} = Images.create(fromImage: "ubuntu:18.04")
    assert {:ok, %{Id: id}} = Containers.create(nil, %{image: "ubuntu:18.04"})
    assert {:error, :bad_request, %{message: _}} = Containers.get_archive(id, %{})

    assert {:ok, archive} = Containers.get_archive(id, %{path: "/etc/passwd"})
    assert is_binary(archive)
  end

  test "Put archive" do
    content = "this is the content"
    basename = "dockerex.txt"
    filename = Path.join(["/tmp", basename])
    tar_filename = Path.join(["/tmp", "dockerex.tar"])

    assert :ok == File.write!(filename, content)

    assert :ok ==
             :erl_tar.create(tar_filename, [
               {String.to_charlist(basename), String.to_charlist(filename)}
             ])

    assert {:ok, stream} = File.read(tar_filename)

    assert {:ok, _progress} = Images.create(fromImage: "ubuntu:18.04")
    assert {:ok, %{Id: id}} = Containers.create(nil, %{image: "ubuntu:18.04"})
    assert :ok = Containers.put_archive(id, stream, %{path: "/tmp"})
    assert {:ok, "dockerex.txt" <> archive} = Containers.get_archive(id, %{path: filename})
    assert archive =~ content
  end

  test "Start, wait, get logs, and stop a container" do
    assert {:ok, _progress} = Images.create(fromImage: "ubuntu:18.04")

    assert {:ok, %{Id: id}} =
             Containers.create(nil, %{Image: "ubuntu:18.04", Cmd: ["ls", "-alR"]})

    assert :ok = Containers.start(id)

    ## Since command takes a long time, cannot start the container again
    assert {:error, :not_modified, nil} = Containers.start(id)

    assert {:ok, %{Error: nil, StatusCode: 0}} = Containers.wait(id)
    assert {:ok, logs} = Containers.logs(id)
    assert [frame | _frames] = logs
    assert %{data: ".:\n", size: 3, stream_type: :stdout} = frame

    ## Since command has already finished and the container is stopped, stop will fail
    assert {:error, :not_modified, nil} = Containers.stop(id)
  end

  test "Start and stop a container" do
    assert {:ok, _progress} = Images.create(fromImage: "ubuntu:18.04")

    assert {:ok, %{Id: id}} =
             Containers.create(nil, %{Image: "ubuntu:18.04", Cmd: ["ls", "-alR"]})

    ## Since container was not started, stop fails
    assert {:error, :not_modified, nil} = Containers.stop(id)

    assert :ok = Containers.start(id)
    assert :ok = Containers.stop(id)
  end
end
