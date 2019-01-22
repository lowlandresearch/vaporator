defmodule Vaporator.DropboxTest do
  use ExUnit.Case
  doctest Vaporator

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}

  # setup_all do
  #   HTTPoison.start()
  # end

  test "lists the root directory" do
    assert length(Map.keys(Vaporator.Cloud.list_folder(@dbx, "/"))) > 0
  end
end
