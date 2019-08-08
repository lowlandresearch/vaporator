defmodule Vaporator.Settings do
  def defaults do
    [
      wireless: [ssid: nil, psk: nil, key_mgmt: :NONE],
      client: [sync_dirs: [], poll_interval: 600_000, sync_enabled?: true],
      cloud: [provider: %Vaporator.Cloud.Dropbox{}]
    ]
  end

  def default?(record, key) do
    default_setting =
      defaults()
      |> Keyword.fetch!(record)
      |> Keyword.fetch!(key)

    default_setting != get!(record, key)
  end

  def required do
    [:ssid, :key_mgmt, :sync_dirs, :provider]
  end

  def required?({key, _}) do
    key in required()
  end

  def init do
    Enum.map(
      defaults(),
      fn {k, v} ->
        put(k, v, overwrite: false)
      end
    )
  end

  def exists?(record) do
    case PersistentStorage.get(:settings, record) do
      nil -> false
      _ -> true
    end
  end

  def set? do
    set?(defaults(), [])
  end

  def set?(record) do
    defaults()
    |> Enum.filter(fn {k, _} -> k == record end)
    |> set?([])
  end

  defp set?([], result) do
    false not in List.flatten(result)
  end

  defp set?(records, result) do
    [h | t] = records
    set?(h, t, result)
  end

  defp set?({record, settings}, t, result) do
    all_set? =
      settings
      |> Enum.filter(&required?/1)
      |> Keyword.keys()
      |> Enum.map(&default?(record, &1))

    set?(t, [all_set? | result])
  end

  @doc """
  Retrives current settings
  """
  def get do
    defaults()
    |> Keyword.keys()
    |> Enum.map(fn k -> {k, get!(k)} end)
  end

  def get(record) do
    if exists?(record) do
      {:ok, PersistentStorage.get(:settings, record)}
    else
      {:error, :record_not_found}
    end
  end

  def get!(record) do
    {:ok, setting} = get(record)
    setting
  end

  def get(record, key) do
    Keyword.fetch(get!(record), key)
  end

  def get!(record, key) do
    Keyword.fetch!(get!(record), key)
  end

  @doc """
  Updates settings

  Returns `:ok`
  """
  def put(record, value) do
    PersistentStorage.put(:settings, record, value)
  end

  def put(record, value, overwrite: true), do: put(record, value)

  def put(record, value, overwrite: false) do
    if exists?(record) do
      :noop
    else
      put(record, value)
    end
  end

  def put(record, key, value) do
    new_setting =
      get!(record)
      |> Keyword.replace!(key, value)

    put(record, new_setting)
  end

  def delete(record) do
    PersistentStorage.delete(:settings, record)
  end

  def reset do
    defaults()
    |> Keyword.keys()
    |> Enum.map(&delete/1)

    init()
  end
end
