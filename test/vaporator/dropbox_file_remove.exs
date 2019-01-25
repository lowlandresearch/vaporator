defmodule Vaporator.DropboxFileRemoveTest do
  use ExUnit.Case

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}

  setup_all do
    {:ok, fp} = File.open("./remove-test.txt", [:write])
    IO.binwrite(fp, "upload test data")
    File.close(fp)
  end

  test "removing a file" do
    {:ok, _} = Vaporator.CloudFs.file_upload(
      @dbx, "./remove-test.txt", "/vaporator/test/remove-test.txt"
    )
    
    {:ok, meta} = Vaporator.CloudFs.file_remove(
      @dbx, "/vaporator/test/remove-test.txt"
    )

    # Access protocol not available by default, must use dot access
    assert meta.path == "/vaporator/test/remove-test.txt"
    
  end
end
