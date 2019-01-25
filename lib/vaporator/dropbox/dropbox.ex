defmodule Vaporator.Dropbox do
  require Logger
  @moduledoc """
  REST API Interface with Dropbox

  TODO:

  - Better, more descriptive error messaging/routing
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

  def auth_headers(dbx) do
    %{"Authorization" => "Bearer #{dbx.access_token}"}
  end

  def post_api(dbx, url_path, body \\ "") do
    post_request(dbx, "#{@api_url}#{url_path}", body, json_headers())
  end

  @doc """
  Prepare file upload POST requests

  Args:

  - dbx (Vaporator.Dropbox): Dropbox client
  - url_path (binary): URL path to be added to @content_url base URL
  - local_path (binary): Local file system path
  - api_args (Map): Dropbox API file transfer arguments to be
      associated with "Dropbox-API-Arg" header key
  - headers (Map): Additional headers. Will default to Content-Type =>
      octet-stream for normal file uploads.

  """
  def post_upload(dbx, url_path, local_path, api_args \\ %{}, headers \\ %{}) do
    post_file_transfer(
      dbx, url_path, {:file, local_path}, api_args,
      Map.merge(%{"Content-Type" => "application/octet-stream"}, headers)
    )
  end

  @doc """
  Prepare file download POST requests

  Args:

  - dbx (Vaporator.Dropbox): Dropbox client
  - url_path (binary): URL path to be added to @content_url base URL
  - data (Map): POST body data
  - api_args (Map): Dropbox API file transfer arguments to be
      associated with "Dropbox-API-Arg" header key
  - headers (Map): Additional headers. Will default to Content-Type =>
      octet-stream for normal file uploads.

  """
  def post_download(
    dbx, url_path, data \\ [], api_args \\ %{}, headers \\ %{}
  ) do
    post_file_transfer(
      dbx, url_path, data, headers, api_args,
      &process_download_response/1 # Downloads need to be processed
                                   # differently
    )
  end

  @doc """
  Prepare file-content-related POST requests

  The /2 and /3 exist because uploads use the default response
  processor (process_json_response), and downloads require a download
  response processor (process_download_response).

  File transfers are different from normal API requests, in that they
  have a set of `Dropbox-API-Arg` arguments that must be added to the
  header, as well has needing to use the @content_url base URL.

  TODO: Implement/integrate automagical pagination, perhaps through
  some sort of lazily-loaded sequence generator.
  
  """
  def post_file_transfer(dbx, url_path, body, api_args, headers) do
    post_file_transfer(
      dbx, url_path, body, api_args, headers, &process_json_response/1
    )
  end
  def post_file_transfer(dbx, url_path, body, api_args, headers, processor) do
    case Poison.encode(api_args) do
      {:ok, encoded} ->
        post_request(
          dbx,
          "#{@content_url}#{url_path}", # Needs @content_url
          body,                   
          Map.merge(               # API header keys
            %{"Dropbox-API-Arg": encoded},
            headers             # e.g. Content-Type => octet for
                                # uploads
          ),
          processor             # default: process_json_response
        )
      {:error, error} ->
        Logger.error("Error in Poison encoding")
        {:error, error}
    end
  end

  @doc """
  Prepare general POST requests

  This is the last stop for all API POSTs (both purely API and
  file-transfer-related). It does only two things:

  - Augments the given headers with token authentication
  - Sends the data to HTTPoison.post and processes it with a provided
    `processor` function
  
  """
  def post_request(dbx, url, body, headers) do
    post_request(dbx, url, body, headers, &process_json_response/1)
  end
  def post_request(dbx, url, body, headers, processor) do
    headers = Map.merge(headers, auth_headers(dbx))
    case HTTPoison.post(url, body, headers) do
      {:ok, response} -> processor.(response)
      {:error, reason} ->
        Logger.error("Error with HTTPoison POST: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Process a JSON response from the REST API

  - Decodes and returns body (as Map) if status code is 200 and body
    decodes correctly
  
  - Returns the following error "signals"
      - :bad_decode for problems decoding JSON body
      - :bad_status for status codes >= 400 and <= 599
      - :unhandled_status for any other status code
  """
  def process_json_response(%HTTPoison.Response{status_code: 200,
                                                body: body}) do
    case Poison.decode(body) do
      {:ok, term} -> {:ok, term}
      {:error, error} -> {:error, {:bad_decode, error}}
    end
  end
  def process_json_response(%HTTPoison.Response{status_code: status_code,
                                           body: body}) do
    cond do
      status_code in 400..599 ->
        {:error, {:bad_status,
                  {:status_code, status_code}, JSON.decode(body)}}
      true ->
        {:error, {:unhandled_status, {:status_code, status_code}, body}}
    end
  end

  @doc """
  Process a JSON response from the REST API

  - Decodes and returns body binary content and headers (as
    Vaporator.CloudFs.FileContent) if status code is 200
  
  - Returns the following error "signals"
      - :bad_status for status codes >= 400 and <= 599
      - :unhandled_status for any other status code
  """
  def process_download_response(%HTTPoison.Response{status_code: 200,
                                                    body: body,
                                                    headers: headers}) do
    {:ok, %Vaporator.CloudFs.FileContent{content: body, headers: headers}}
  end    
  def process_download_response(%HTTPoison.Response{status_code: status_code,
                                                    body: body}) do
    cond do
      status_code in 400..599 ->
        {:error, {:bad_status,
                  {:status_code, status_code}, JSON.decode(body)}}
      true ->
        {:error, {:unhandled_status, {:status_code, status_code}, body}}
    end
  end

  @doc """
  Convert a Dropbox file/folder metadata element into a
  Vaporator.CloudFs.Meta element
  """
  def dropbox_meta_to_cloudfs(meta) do
    %Vaporator.CloudFs.Meta{
      meta: meta,
      type: String.to_atom(meta[".tag"]),
      name: meta["name"],
      path: meta["path_display"],
    }
  end

  @doc """
  Prepares/transforms a Dropbox path
  """
  def prep_path("/"), do: ""
  def prep_path(path), do: path

  @doc """
  Is the dbx_path a directory to place the local_path, or is it an
  absolute path name for the file?

  This currently only returns true if the dbx_path ends in a /

  """
  def dbx_path_is_dir?(_local_path, dbx_path) do
    String.ends_with?(dbx_path, ["/"])
  end

  @doc """
  Prepare dbx_path for upload, given a local_path.

  If the dbx_path is a directory, then add the local_path's file name
  (i.e. basename) to the end of dbx_path. Otherwise, leave the
  dbx_path as is.
  """
  def prep_dbx_path(local_path, dbx_path) do
    if dbx_path_is_dir?(local_path, dbx_path) do
      Path.join(dbx_path, Path.basename(local_path))
    else
      dbx_path
    end
  end

end

defimpl Vaporator.CloudFs, for: Vaporator.Dropbox do
  require Logger

  import Vaporator.Dropbox, only: [post_api: 3,
                                   prep_path: 1, prep_dbx_path: 2,
                                   dropbox_meta_to_cloudfs: 1,
                                   post_download: 5,
                                   post_upload: 5]

  def list_folder(dbx, path, args \\ %{}) do
    body = Map.merge(%{:path => prep_path(path)}, args)
    case Poison.encode(body) do
      {:ok, encoded_body} -> 
        case post_api(dbx, "/files/list_folder", encoded_body) do
          {:ok, result_meta=%{"entries" => entries}} ->
            results = for meta <- entries do
                dropbox_meta_to_cloudfs(meta)
              end
            {:ok, %Vaporator.CloudFs.ResultsMeta{results: results,
                                                 meta: result_meta}}
          {:ok, _} ->
            Logger.error("No entries listed in response object")
            {:error, "No entries listed in response object"}
          {:error, error} ->
            Logger.error("Error in API POST: #{error}")
            {:error, error}
        end

      {:error, error} ->
        Logger.error("Error with Poison encoding: #{error}")
        {:error, error}
    end
  end

  def get_metadata(dbx, path, args \\ %{}) do
    body = Map.merge(%{:path => prep_path(path)}, args)
    case Poison.encode(body) do
      {:ok, encoded_body} ->
        case post_api(dbx, "/files/get_metadata", encoded_body) do
          {:ok, meta} -> dropbox_meta_to_cloudfs(meta)
          {:error, error} -> {:error, error}
        end
      {:error, error} ->
        Logger.error("Error in Poison encoding: {#error}")
        {:error, error}
    end
  end

  def file_download(dbx, path, dbx_api_args \\ %{}) do
    post_download(dbx, "files/download", [], dbx_api_args, %{:path => path})
  end

  def file_upload(dbx, local_path, dbx_path, args \\ %{}) do
    post_upload(
      dbx, "files/upload", local_path,
      Map.merge(%{:path => prep_dbx_path(local_path, dbx_path),
                  :mode => "overwrite",
                  :autorename => true,
                  :mute => false}, args),
      %{}
    )
  end

end
