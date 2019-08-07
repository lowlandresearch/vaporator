defmodule Vaporator.Settings do

  def defaults do
    [
      wireless: [ssid: nil, psk: nil, key_mgmt: :NONE],
      client: [sync_dirs: [], poll_interval: 600_000, sync_enabled?: true],
      cloud: [provider: %Vaporator.Cloud.Dropbox{}]
    ]
  end

  def default?(record, key) do
    Keyword.fetch!(defaults(), key) != get!(record, key)
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
    |> Keyword.fetch(record)
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
    |> get_by_keys()
  end

  def get(record) do
    if exists?(record) do
      PersistentStorage.get(:settings, record)
    else
      []
    end
  end

  def get(record, key) do
    Keyword.fetch(get(record), key)
  end

  def get!(record, key) do
    Keyword.fetch!(get(record), key)
  end

  def get_by_key(key) do
    get_by_keys([key])
  end

  def get_by_keys(keys) when is_list(keys) do
    Enum.filter(get(), fn {k, v} -> k in keys end)
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
      PersistentStorage.get(:settings, record)
      |> Keyword.replace!(key, value)

    put(record, new_setting)
  end
end
