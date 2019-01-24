defmodule Vaporator.DropboxFileDownloadTest do
  use ExUnit.Case

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}

  test "download a file" do
    {:ok, %{content: content}} = Vaporator.CloudFs.file_download(
      @dbx, "/vaporator/test/test.txt"
    )
    assert content == "some data"
  end

end
