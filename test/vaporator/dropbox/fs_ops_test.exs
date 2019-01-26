defmodule Vaporator.DropboxFsOpsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}
  @test_dir Application.get_env(:vaporator, :test_dir)
  @test_file Application.get_env(:vaporator, :test_file)
  @test_file_path "#{@test_dir}#{@test_file}"

  setup_all do
    {:ok, fp} = File.open("./#{@test_file}", [:write])
    IO.binwrite(fp, "upload test data")
    File.close(fp)

    on_exit fn ->
      File.rm("./#{@test_file}")
    end
  end

  test "upload a file" do
    {:ok, %{name: name}} = Vaporator.CloudFs.file_upload(
      @dbx, "./#{@test_file}", @test_dir
    )
    
    assert name == @test_file
  end

  test "download a file" do
    {:ok, %{content: content}} = Vaporator.CloudFs.file_download(
      @dbx, @test_file_path
    )
    assert content == "upload test data"
  end

  test "get_metadata from dropbox folder that exists" do
    use_cassette "cloudfs/get_metadata/folder" do
      {:ok, meta} = Vaporator.CloudFs.get_metadata(
        @dbx,
        @test_dir
      )
      assert meta.type == :folder
    end
  end

  test "get_metadata from dropbox file that exists" do
    use_cassette "cloudfs/get_metadata/file" do
      {:ok, meta} = Vaporator.CloudFs.get_metadata(
        @dbx,
        @test_file_path
      )
      assert meta.type == :file
    end
  end

  test "get_metadata from dropbox item that doesn't exists" do
    use_cassette "cloudfs/get_metadata/not_found" do
      {:error, {reason, _}} = Vaporator.CloudFs.get_metadata(
        @dbx,
        "/fake"
      )
      assert reason == :path_not_found
    end
  end

  test "removing a file" do

    {:ok, meta} = Vaporator.CloudFs.file_remove(
      @dbx, @test_file_path
    )

    # Access protocol not available by default, must use dot access
    assert meta.path == @test_file_path
    
  end

  test "lists the root directory" do
    use_cassette "cloudfs/list_folder/root_dir" do
      {status, _} = Vaporator.CloudFs.list_folder(@dbx, "/")
      assert status == :ok
    end
  end

  test "list_folder: empty folder" do
    use_cassette "cloudfs/list_folder/no_files" do
      {:error, {reason, _}} = Vaporator.CloudFs.list_folder(
        @dbx,
        @test_dir
      )
      assert reason == :no_entries
    end
  end

  test "list_folder: path not found" do
    use_cassette "cloudfs/list_folder/not_found" do
      {:error, {reason, _}} = Vaporator.CloudFs.list_folder(
        @dbx,
        "/fake"
      )
      assert reason == :path_not_found
    end
  end

end
