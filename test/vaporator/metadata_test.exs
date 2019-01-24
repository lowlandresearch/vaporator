defmodule Vaporator.DropboxTestTwo do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @dbx %Vaporator.Dropbox{
    access_token: System.get_env("DROPBOX_ACCESS_TOKEN")
  }

  @test_dir "/vaporator/test"
  @test_file "#{@test_dir}/test.txt"

  setup_all do
    HTTPoison.start
    # TODO: Create @test_dir
    # TODO: Create @test_file

    on_exit fn ->
      # TODO: Remove @test_dir
      IO.puts("This will remove @test_dir")
    end
  end

  test "get_metadata from dropbox folder that exists" do
    use_cassette "cloudfs/get_metadata/folder" do
      meta = Vaporator.Cloud.get_metadata(
        @dbx,
        @test_dir,
        %{}
      )
      assert meta[".tag"] == "folder"
    end
  end

  test "get_metadata from dropbox file that exists" do
    use_cassette "cloudfs/get_metadata/file" do
      meta = Vaporator.Cloud.get_metadata(
        @dbx,
        @test_file,
        %{}
      )
      assert meta[".tag"] == "file"
    end
  end

  test "get_metadata from dropbox item that doesn't exists" do
    use_cassette "cloudfs/get_metadata/not_found" do
      meta = Vaporator.Cloud.get_metadata(
        @dbx,
        "/fake",
        %{}
      )
      assert meta == nil
    end
  end

end