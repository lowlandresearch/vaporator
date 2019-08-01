defmodule SettingStore do

  def exists?(setting) do
    case PersistentStorage.get(:settings, setting) do
      nil -> false
      _ -> true
    end
  end

  # KeywordList
  # Take first one, get settings, check equal with default
  # return result and tail

  def set?(settings) do
    set?(settings, [])
  end

  defp set?([], result) do
    false in result
  end

  defp set?(settings, result) do
    [h | t] = settings
    set?(h, t, result)
  end

  defp set?({setting, default}, t, result) do
    default_setting? =
      setting
      |> get()
      |> Keyword.equal?(default)

    set?(t, [default_setting? | result])
  end

  @doc """
  Retrives current settings
  """
  def get(setting) do
    PersistentStorage.get(:settings, setting)
  end

  def get(setting, key) do
    Keyword.fetch(get(setting), key)
  end

  def get!(setting, key) do
    Keyword.fetch!(get(setting), key)
  end

  def get_by_keys(keys) when is_list(keys) do
    Enum.map(keys, fn k -> {k, get(k)} end)
  end

  @doc """
  Updates settings

  Returns `:ok`
  """
  def put(setting, value) do
    PersistentStorage.put(:settings, setting, value)
  end

  def put(setting, value, [overwrite: true]), do: put(setting, value)

  def put(setting, value, [overwrite: false]) do
    if exists?(setting) do
      :noop
    else
      put(setting, value)
    end
  end

  def put(setting, key, value) do
    new_value = 
      PersistentStorage.get(:settings, setting)
      |> Keyword.replace!(key, value)

    put(setting, new_value)
  end



end