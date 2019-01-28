defmodule Vaporator.DropboxCopyMoveFilesTest do
  use ExUnit.Case

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}
  @test_dir Application.get_env(:vaporator, :test_dir)

  test "copy a file" do
    path = "copy-test.txt"
    from_path = Path.join(@test_dir, "copy-test.txt")
    to_path = Path.join(@test_dir, "copy-test-to.txt")

    File.write(path, "copy test")
    {:ok, _} = Vaporator.CloudFs.file_upload(@dbx, path, from_path)

    {:ok, copy_meta} = Vaporator.CloudFs.file_copy(@dbx, from_path, to_path)

    assert copy_meta.path == to_path
  end

  test "move a file" do
    path = "move-test.txt"
    from_path = Path.join(@test_dir, "move-test.txt")
    to_path = Path.join(@test_dir, "move-test-to.txt")

    File.write(path, "move test")
    {:ok, _} = Vaporator.CloudFs.file_upload(@dbx, path, from_path)

    {:ok, move_meta} = Vaporator.CloudFs.file_move(@dbx, from_path, to_path)

    assert move_meta.path == to_path
  end
end
