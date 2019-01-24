defmodule Vaporator.DropboxTestTwo do
  use ExUnit.Case, async: false

  @dbx %Vaporator.Dropbox{
    access_token: System.get_env("DROPBOX_ACCESS_TOKEN")
  }

  @test_dir "/vaporator/test"
  @test_file "#{@test_dir}/test.txt"

  setup_all do
    # TODO: Create @test_dir
    # TODO: Create @test_file

    on_exit fn ->
      # TODO: Remove @test_dir
      IO.puts("This will remove @test_dir")
    end
  end

  test "get_metadata from dropbox folder that exists" do
    meta = Vaporator.Cloud.get_metadata(
      @dbx,
      @test_dir,
      %{}
    )
    assert meta[".tag"] == "folder"
  end

  test "get_metadata from dropbox file that exists" do
    meta = Vaporator.Cloud.get_metadata(
      @dbx,
      @test_file,
      %{}
    )
    assert meta[".tag"] == "file"
  end

  test "get_metadata from dropbox item that doesn't exists" do
    meta = Vaporator.Cloud.get_metadata(
      @dbx,
      "/fake",
      %{}
    )
    assert meta == nil
  end

end