defmodule Vaporator.DropboxTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @dbx %Vaporator.Dropbox{
    access_token: System.get_env("DROPBOX_ACCESS_TOKEN")
  }

  test "lists the root directory" do
    use_cassette "cloudfs/list_folder/root_dir" do
      assert length(
        Map.keys(
          Vaporator.Cloud.list_folder(@dbx, "/")
        )
      ) > 0
    end
  end

  test "sets header with Content-Type json" do
    assert Vaporator.Dropbox.json_headers == %{"Content-Type" => "application/json"}
  end

  test "sets header with Authorization" do
    assert Vaporator.Dropbox.headers(@dbx) == %{"Authorization" => "Bearer #{@dbx.access_token}"}
  end

  test "post_api: successful call" do
    use_cassette "dropbox/post_api/success" do
      body = %{"path" => ""}
      result = to_string(Poison.Encoder.encode(body, %{}))
      response = Vaporator.Dropbox.post_api(
        @dbx,
        "/files/list_folder",
        result
      )
      assert {:ok, _} = response
    end
  end

  test "post_api: bad url supplied" do
    use_cassette "dropbox/post_api/bad_url" do
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
  end

  test "post_api: no body supplied" do
    use_cassette "dropbox/post_api/no_body" do
      response = Vaporator.Dropbox.post_api(
        @dbx,
        "/files/list_folder"
      )
      {:error,{_,_,{_,{_,reason}}}} = response
      assert String.contains?(reason, "request body")
    end
  end

  test "post_api: Invalid OAuth token supplied" do
    use_cassette "dropbox/post_api/bad_token" do
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

  test "download_response: good status_code" do
    body = %{"test" => "data"}
    code = 200

    response = %HTTPoison.Response{
      status_code: code,
      body: Poison.Encoder.encode(body, %{}),
      headers: %{header: "setting"}
    }

    response = Vaporator.Dropbox.download_response(response)
    %{body: return_body, headers: return_headers} = response
    assert return_body == response.body
    assert return_headers == response.headers
  end

  test "download_response: bad status_code returns json decoded body" do
    body = %{"test" => "data"}
    code = 400

    response = %HTTPoison.Response{
      status_code: code,
      body: Poison.Encoder.encode(body, %{})
    }

    response = Vaporator.Dropbox.download_response(response)
    {{:status_code, return_code}, {:ok, decoded_body}} = response
    assert return_code == code
    assert decoded_body == body
  end

  test "process_response: good status_code with successful decode" do
    body = %{"test" => "data"}
    code = 200

    response = %HTTPoison.Response{
      status_code: code,
      body: Poison.Encoder.encode(body, %{})
    }

    response = Vaporator.Dropbox.process_response(response)
    {:ok, decoded_body} = response
    assert decoded_body == body
  end

  test "process_response: good status_code with bad decode" do
    # TODO: Figure out how to trigger a Poison.DecodeError
  end

  test "process_response: bad status_code returns error" do
    body = %{"test" => "data"}
    code = 400

    response = %HTTPoison.Response{
      status_code: code,
      body: Poison.Encoder.encode(body, %{})
    }

    response = Vaporator.Dropbox.process_response(response)
    {:error, {reason, _, _}} = response
    assert reason == :bad_status
  end

  test "process_response: unhandled status_code returns error" do
    body = %{"test" => "data"}
    code = 301

    response = %HTTPoison.Response{
      status_code: code,
      body: Poison.Encoder.encode(body, %{})
    }

    response = Vaporator.Dropbox.process_response(response)
    {:error, {reason, _, _}} = response
    assert reason == :unhandled_status
  end

  test "post_request: successful response" do
    use_cassette "dropbox/post_request/success" do
      api_url = Application.get_env(:vaporator, :api_url)
      body = %{"path" => ""}

      response = Vaporator.Dropbox.post_request(
        @dbx,
        "#{api_url}/files/list_folder",
        Poison.Encoder.encode(body, %{}),
        Vaporator.Dropbox.json_headers
      )
      {status, _} = response
      assert status == :ok
    end
  end

end
