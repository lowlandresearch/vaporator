defmodule SettingStore do

  def create(table, value) do
    PersistentStorage.put(
      :settings,
      table,
      value
    )
    {:ok, :setting_created}
  end
  
  @doc """
  Retrives current settings
  """
  def get(table) do
    PersistentStorage.get(:settings, table)
  end

  def get(table, key) do
    setting = get(table)
    Map.fetch(setting, key)
  end

  def get!(table, key) do
    {:ok, value} = get(table, key)
    value
  end

  @doc """
  Updates settings

  Returns `:ok`
  """
  def update(table, key, value) do
    setting = PersistentStorage.get(:settings, table)
    new_setting = Map.replace!(setting, key, value)
    update(table, new_setting)
  end

  defp update(table, setting) do
    PersistentStorage.put(:settings, table, setting)
  end

end