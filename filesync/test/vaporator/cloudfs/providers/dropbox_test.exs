defmodule Filesync.DropboxTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @dbx %Filesync.Dropbox{
    access_token: Application.get_env(:filesync, :dbx_token)
  }
  @test_dir Application.get_env(:filesync, :test_dir)
  @test_file Application.get_env(:filesync, :test_file)

  @test_files %{
    cloudfs: %{
      created_file: Path.join(@test_dir, @test_file),
      copied_file: Path.join(@test_dir, "copy_#{@test_file}"),
      moved_file: Path.join(@test_dir, "move_#{@test_file}")
    },
    clientfs: %{
      created_file: Path.join(".", @test_file),
      copied_file: Path.join(".", "copy_#{@test_file}"),
      moved_file: Path.join(".", "move_#{@test_file}")
    }
  }

  setup_all do
    File.write(@test_files.clientfs.created_file, "update test data")

    on_exit(fn ->
      Enum.map(
        Map.values(@test_files.clientfs),
        &File.rm/1
      )
    end)
  end

  test "upload a file" do
    use_cassette "cloudfs/file_ops/upload_file" do
      {:ok, %{name: name}} =
        Filesync.CloudFs.file_upload(
          @dbx,
          @test_files.clientfs.created_file,
          @test_dir
        )

      assert name == @test_file
    end
  end

  test "download a file" do
    use_cassette "cloudfs/file_ops/download_file" do
      {:ok, %{content: content}} =
        Filesync.CloudFs.file_download(
          @dbx,
          @test_files.cloudfs.created_file
        )

      assert content == "update test data"
    end
  end

  test "copy a file" do
    from_path = @test_files.cloudfs.created_file
    to_path = @test_files.cloudfs.copied_file

    use_cassette "cloudfs/file_ops/copy_file" do
      {:ok, copy_meta} = Filesync.CloudFs.file_copy(@dbx, from_path, to_path)
      assert copy_meta.path == to_path
    end
  end

  test "move a file" do
    from_path = @test_files.cloudfs.copied_file
    to_path = @test_files.cloudfs.moved_file

    use_cassette "cloudfs/file_ops/move_file" do
      {:ok, move_meta} = Filesync.CloudFs.file_move(@dbx, from_path, to_path)
      assert move_meta.path == to_path
    end
  end

  test "get_metadata from dropbox folder that exists" do
    use_cassette "cloudfs/get_metadata/folder" do
      {:ok, meta} = Filesync.CloudFs.get_metadata(@dbx, @test_dir)

      assert meta.type == :folder
    end
  end

  test "get_metadata from dropbox file that exists" do
    use_cassette "cloudfs/get_metadata/file" do
      {:ok, meta} =
        Filesync.CloudFs.get_metadata(
          @dbx,
          @test_files.cloudfs.created_file
        )

      assert meta.type == :file
    end
  end

  test "get_metadata from dropbox item that doesn't exists" do
    use_cassette "cloudfs/get_metadata/not_found" do
      {:error, {reason, _}} = Filesync.CloudFs.get_metadata(@dbx, "/fake")

      assert reason == :cloud_path_not_found
    end
  end

  test "lists the root directory" do
    use_cassette "cloudfs/list_folder/root_dir" do
      {status, _} = Filesync.CloudFs.list_folder(@dbx, "/")
      assert status == :ok
    end
  end

  test "Dropbox hash function" do
    File.write(@test_files.clientfs.created_file, "test data")

    hash = "824979ede959fefe53082bc14502f8bf041d53997ffb65cbbe3ade5803f7fb76"
    assert Filesync.Dropbox.dbx_hash!(@test_files.clientfs.created_file) == hash
  end

  test "update a file" do
    # First, create and upload the file
    File.write(@test_files.clientfs.created_file, "update test data")

    use_cassette "/cloudfs/file_ops/upload_file" do
      {:ok, meta} =
        Filesync.CloudFs.file_upload(
          @dbx,
          @test_files.clientfs.created_file,
          @test_files.cloudfs.created_file
        )

      assert meta.path == @test_files.cloudfs.created_file

      hash = "6eec1c708f7d1962bd125e2148e4b8580230d7b1ab1e810a048b10575f89edbe"
      assert meta.meta["content_hash"] == hash
    end

    use_cassette "/cloudfs/file_ops/update_file_without_change" do
      {:ok, meta} =
        Filesync.CloudFs.file_update(
          @dbx,
          @test_files.clientfs.created_file,
          @test_files.cloudfs.created_file
        )

      assert meta.path == @test_files.cloudfs.created_file

      hash = "6eec1c708f7d1962bd125e2148e4b8580230d7b1ab1e810a048b10575f89edbe"
      assert meta.meta["content_hash"] == hash

      expected_server_modified = "2019-02-13T04:42:50Z"
      assert meta.meta["server_modified"] == expected_server_modified
    end

    File.write(@test_files.clientfs.created_file, "different test data")

    use_cassette "/cloudfs/file_ops/update_file_with_change" do
      {:ok, meta} =
        Filesync.CloudFs.file_update(
          @dbx,
          @test_files.clientfs.created_file,
          @test_files.cloudfs.created_file
        )

      assert meta.path == @test_files.cloudfs.created_file

      hash = "5b81988c6b0a3d4a95edf8cf5c505e1410286dbff0c6d9201de80872981eabf9"
      assert meta.meta["content_hash"] == hash

      unexpected_server_modified = "2019-02-13T04:42:50Z"
      assert meta.meta["server_modified"] != unexpected_server_modified
    end
  end

  test "removing a file" do
    use_cassette "/cloudfs/file_ops/remove_file" do
      {:ok, meta} =
        Filesync.CloudFs.file_remove(
          @dbx,
          @test_files.cloudfs.created_file
        )

      assert meta.path == @test_files.cloudfs.created_file
    end
  end

  test "list_folder: empty folder" do
    use_cassette "cloudfs/list_folder/no_files" do
      {:error, {reason, _}} = Filesync.CloudFs.list_folder(@dbx, @test_dir)

      assert reason == :no_entries
    end
  end

  test "list_folder: path not found" do
    use_cassette "cloudfs/list_folder/not_found" do
      {:error, {reason, _}} = Filesync.CloudFs.list_folder(@dbx, "/fake")

      assert reason == :cloud_path_not_found
    end
  end
end
