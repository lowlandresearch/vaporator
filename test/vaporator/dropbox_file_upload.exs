defmodule Vaporator.DropboxFileDownloadTest do
  use ExUnit.Case

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}

  setup_all do
    {:ok, fp} = File.open("./upload-test.txt", [:write])
    IO.binwrite(fp, "upload test data")
    File.close(fp)
  end

  test "upload a file" do
    {:ok, meta} = Vaporator.CloudFs.file_upload(
      @dbx, "./upload-test.txt", "/vaporator/test/upload-test.txt"
    )
    
    {:ok, %{content: content}} = Vaporator.CloudFs.file_download(
      @dbx, "/vaporator/test/upload-test.txt"
    )
    assert content == "upload test data"
  end
end
