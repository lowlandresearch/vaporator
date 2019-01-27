defmodule Vaporator.DropboxSyncFilesTest do
  use ExUnit.Case

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}
  @test_dir Application.get_env(:vaporator, :test_dir)

  test "sync a directory" do
    # First, create the directory
    sync_root = "./sync-test-dir"
    sync_dir = Path.join(sync_root, "/sub1/sub2")
    a_path = Path.join([sync_root, "a.txt"])
    b_path = Path.join([sync_root, "sub1", "b.txt"])
    c_path = Path.join([sync_root, "sub1", "sub2", "c.txt"])
    File.mkdir_p(sync_dir)
    File.write(a_path, "test a.txt")
    File.write(b_path, "test b.txt")
    File.write(c_path, "test c.txt")

    Vaporator.CloudFs.sync_files(@dbx, sync_root, @test_dir)

    {:ok, a_meta} = Vaporator.CloudFs.get_metadata(
      @dbx, Path.join(@test_dir, "a.txt")
    )
    assert a_meta.path == Path.join(@test_dir, "a.txt")
    assert a_meta.meta["content_hash"] == Vaporator.Dropbox.dbx_hash!(a_path)
    
    {:ok, b_meta} = Vaporator.CloudFs.get_metadata(
      @dbx, Path.join([@test_dir, "sub1", "b.txt"])
    )
    assert b_meta.path == Path.join([@test_dir, "sub1", "b.txt"])
    assert b_meta.meta["content_hash"] == Vaporator.Dropbox.dbx_hash!(b_path)
    
    {:ok, c_meta} = Vaporator.CloudFs.get_metadata(
      @dbx, Path.join([@test_dir, "sub1", "sub2", "c.txt"])
    )
    assert c_meta.path == Path.join([@test_dir, "sub1", "sub2", "c.txt"])
    assert c_meta.meta["content_hash"] == Vaporator.Dropbox.dbx_hash!(c_path)
    
  end
end
