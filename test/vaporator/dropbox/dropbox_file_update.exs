defmodule Vaporator.DropboxFileUpdateTest do
  use ExUnit.Case

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}

  test "Dropbox hash function" do
    File.write("./dbx-hash-test.txt", "test data")
    assert Vaporator.Dropbox.dbx_hash!(
      "./dbx-hash-test.txt"
    ) == "824979ede959fefe53082bc14502f8bf041d53997ffb65cbbe3ade5803f7fb76"
  end

  test "update a file" do
    # First, create and upload the file
    File.write("./update-test.txt", "update test data")
    {:ok, meta} = Vaporator.CloudFs.file_upload(
      @dbx, "./update-test.txt", "/vaporator/test/update-test.txt"
    )

    assert meta.path == "/vaporator/test/update-test.txt"
    assert meta.meta["content_hash"] == "6eec1c708f7d1962bd125e2148e4b8580230d7b1ab1e810a048b10575f89edbe"
    server_modified = meta.meta["server_modified"]
    
    {:ok, meta} = Vaporator.CloudFs.file_update(
      @dbx, "./update-test.txt", "/vaporator/test/update-test.txt"
    )
    assert meta.path == "/vaporator/test/update-test.txt"
    assert meta.meta["content_hash"] == "6eec1c708f7d1962bd125e2148e4b8580230d7b1ab1e810a048b10575f89edbe"
    assert meta.meta["server_modified"] == server_modified


    File.write("./update-test.txt", "different test data")
    {:ok, meta} = Vaporator.CloudFs.file_update(
      @dbx, "./update-test.txt", "/vaporator/test/update-test.txt"
    )
    assert meta.path == "/vaporator/test/update-test.txt"
    assert meta.meta["content_hash"] == "5b81988c6b0a3d4a95edf8cf5c505e1410286dbff0c6d9201de80872981eabf9"
    assert meta.meta["server_modified"] != server_modified
    
  end
end
