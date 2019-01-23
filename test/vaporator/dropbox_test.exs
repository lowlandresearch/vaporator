defmodule Vaporator.DropboxTest do
  use ExUnit.Case
  doctest Vaporator

  @dbx %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}

  test "lists the root directory" do
    assert length(Map.keys(Vaporator.Cloud.list_folder(@dbx, "/"))) > 0
  end

  test "sets header with Content-Type json" do
    assert Vaporator.Dropbox.json_headers == %{"Content-Type" => "application/json"}
  end

  test "sets header with Authorization" do
    assert Vaporator.Dropbox.headers(@dbx) == %{"Authorization" => "Bearer #{@dbx.access_token}"}
  end

  test "post_api: successful call" do
    body = %{"path" => ""}
    result = to_string(Poison.Encoder.encode(body, %{}))
    response = Vaporator.Dropbox.post_api(
      @dbx,
      "/files/list_folder",
      result
    )
    assert {:ok, _} = response
  end

  test "post_api: bad url supplied" do
    body = %{"path" => ""}
    result = to_string(Poison.Encoder.encode(body, %{}))
    response = Vaporator.Dropbox.post_api(
      @dbx,
      "/bogus/url",
      result
    )
    {:error,{_,_,{_,{_,reason}}}} = response
    assert String.contains?(reason, "Unknown API")
  end

  test "post_api: No body supplied" do
    body = %{"path" => ""}
    result = to_string(Poison.Encoder.encode(body, %{}))
    response = Vaporator.Dropbox.post_api(
      @dbx,
      "/files/list_folder"
    )
    {:error,{_,_,{_,{_,reason}}}} = response
    assert String.contains?(reason, "request body")
  end

  test "post_api: Invalid OAuth token supplied" do
    body = %{"path" => ""}
    result = to_string(Poison.Encoder.encode(body, %{}))
    response = Vaporator.Dropbox.post_api(
      %Vaporator.Dropbox{access_token: "123456abcd"},
      "/files/list_folder",
      result
    )
    {:error,{_,_,{_,{_,reason}}}} = response
    assert String.contains?(reason, "token is malformed")
  end

end
