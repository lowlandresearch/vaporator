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

  def post_content(dbx, url, body \\ "") do
    headers = json_headers()
    post_request(dbx, "#{@content_url}#{url}", body, headers)
  end

  def post_request(dbx, url, body, headers) do
    headers = Map.merge(headers, headers(dbx))
    case HTTPoison.post(url, body, headers) do
      {:ok, response} -> process_response(response)
      {:error, reason} -> Logger.error("#{reason}");
    end
  end

  def process_response(%HTTPoison.Response{status_code: 200, body: body}) do
    case Poison.decode(body) do
      {:ok, term} -> {:ok, term}
      {:bad_decode, error} ->
        Logger.error("Error with Poison decoding: #{error}")
        {:error, :bad_decode}
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

  def download_response(%HTTPoison.Response{status_code: 200, body: body,
                                            headers: headers}) do
    %{body: body, headers: headers}
  end    

  def download_response(%HTTPoison.Response{status_code: status_code, body: body}) do
    cond do
      status_code in 400..599 ->
        {{:status_code, status_code}, JSON.decode(body)}
    end
  end

end

defimpl Vaporator.Cloud, for: Vaporator.Dropbox do
  import Vaporator.Dropbox, only: [post_api: 3]

  def list_folder(dbx, "/"), do: list_folder(dbx, "")
  def list_folder(dbx, path) do
    body = %{"path" => path}
    result = to_string(Poison.Encoder.encode(body, %{}))
    case post_api(dbx, "/files/list_folder", result) do
      {:ok, %{"entries" => entries}} ->
        for meta <- entries, into: %{} do
          { meta["name"],
            %{meta: Enum.map(meta, fn {k, v} -> {String.to_atom(k), v} end),
              path: meta["path_display"]} }
        end
      _ -> nil
    end
  end

  def get_metadata(dbx, "/", args), do: get_metadata(dbx, "", args)
  def get_metadata(dbx, path, args) do
    body = Map.merge(%{"path" => path}, args)
    result = to_string(Poison.Encoder.encode(body, %{}))
    case post_api(dbx, "/files/get_metadata", result) do
      {:ok, meta} -> meta
      _ -> nil
    end
  end
end
