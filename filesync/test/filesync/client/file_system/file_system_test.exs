defmodule Filesync.Client.FileSystemTest do
  use ExUnit.Case, async: true

  alias Filesync.Client.FileSystem

  test "Parse options" do
    expected = ["-o", "password=bar", "username=foo", "-t", "cifs"]

    opts = [filesystem_type: :cifs, username: "foo", password: "bar"]
    {:ok, actual} = FileSystem.parse_options(opts)

    assert actual == expected 
  end

  test "Parse options with unknown filesystem_type" do
    expected = {:error, :unknown_filesystem_type}

    actual = FileSystem.parse_options([filesystem_type: :foo])
    assert actual == expected
  end

end