defmodule Vaporator.Dropbox do
  require Logger
  @moduledoc """
  REST API Interface with Dropbox
  """

  @enforce_keys [:access_token]
  defstruct [:access_token]

  @api_url Application.get_env(:vaporator, :api_url)
  @content_url Application.get_env(:vaporator, :content_url)

  def json_headers do
    %{"Content-Type" => "application/json"}
  end

  # def auth_headers(auth) do
  #   %{"Authorization" => "Bearer #{auth.access_token}"}
  # end

  def headers(auth) do
    %{"Authorization" => "Bearer #{auth.access_token}"}
  end

  def post_api(dbx, url, body \\ "") do
    headers = json_headers()
    post_request(dbx, "#{@api_url}#{url}", body, headers)
  end

  def post_request(dbx, url, body, headers) do
    headers = Map.merge(headers, headers(dbx))
    case HTTPoison.post(url, body, headers) do
      {:ok, response} -> process_response(response)
      {:error, reason} ->
        Logger.error("Error with HTTPoison POST: #{reason}")
        {:error, reason}
    end
  end

  def process_response(%HTTPoison.Response{status_code: 200, body: body}) do
    case Poison.decode(body) do
      {:ok, term} -> {:ok, term}
      {:error, error} ->
        Logger.error("Error with Poison decoding: #{error}")
        {:error, error}
    end
  end

  def process_response(%HTTPoison.Response{status_code: status_code,
                                           body: body}) do
    cond do
      status_code in 400..599 ->
        {:error, {:bad_status,
                  {:status_code, status_code}, JSON.decode(body)}}
      true ->
        {:error, {:unhandled_status, {:status_code, status_code}, body}}
    end
  end

  def content_request(dbx, url, data, headers) do
    headers = json_headers()
    post_request(dbx, "#{@content_url}#{url}", body, headers)
  end

  def download_request(client, base_url, url, data, headers) do
    headers = Map.merge(headers, headers(client))
    HTTPoison.post!("#{base_url}#{url}", data, headers) |> download_response
  end

  def download_response(%HTTPoison.Response{status_code: 200, body: body,
                                            headers: headers}) do
    %{body: body, headers: headers}
  end    

  def download_response(%HTTPoison.Response{status_code: status_code, body: body}) do
    cond do
      status_code in 400..599 ->
        {:error, {:bad_status,
                  {:status_code, status_code}, JSON.decode(body)}}
      true ->
        {:error, {:unhandled_status, {:status_code, status_code}, body}}
    end
  end

  def dropbox_meta_to_cloudfs(meta) do
    %Vaporator.CloudFs.Meta{
      meta: meta,
      type: String.to_atom(meta[".tag"]),
      name: meta["name"],
      path: meta["path_display"],
    }
  end

  def prep_path("/"), do: ""
  def prep_path(path), do: path

end

defimpl Vaporator.CloudFs, for: Vaporator.Dropbox do
  import Vaporator.Dropbox, only: [post_api: 3, prep_path: 1,
                                   dropbox_meta_to_cloudfs: 1,
                                   download_request: ]

  def list_folder(dbx, path, args \\ %{}) do
    body = Map.merge(%{"path" => prep_path(path)}, args)
    case Poison.encode(body) do
      {:ok, encoded_body} -> 
        case post_api(dbx, "/files/list_folder", encoded_body) do
          {:ok, %{"entries" => entries}} ->
            {:ok, for meta <- entries, do: dropbox_meta_to_cloudfs(meta)}
          {:error, error} ->
            Logger.error("Error in API POST: #{error}")
            {:error, error}
        end

      {:error, error} ->
        Logger.error("Error with encoding: #{error}")
        {:error, error}
    end
    encoded_body = to_string(Poison.Encoder.encode(body, %{}))
  end

  def get_metadata(dbx, path, args \\ %{}) do
    body = Map.merge(%{"path" => prep_path(path)}, args)
    case Poison.encode(body) do
      {:ok, encoded_body} ->
        case post_api(dbx, "/files/get_metadata", encoded_body) do
          {:ok, meta} -> dropbox_meta_to_cloudfs(meta)
          {:error, error} -> {:error, error}
        end
      {:error, error} ->
        Logger.error("Error {#error}")
        {:error, error}
    end
  end

  def file_download(dbx, path, args \\ %{}) do
    path_headers = %{:path => path}

    case Poison.encode(path_headers) do
      {:ok, encoded} ->
        headers = %{"Dropbox-API-Arg" => encoded}
        download_request(
      client,
      Application.get_env(:elixir_dropbox, :upload_url),
      "files/download",
      [],
      headers
    )
  end

end
