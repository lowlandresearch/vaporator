defmodule Filesync.Settings do

  @default_settings [
    client: [sync_dirs: [], poll_interval: 30000],
    cloud: [provider: %Filesync.Cloud.Dropbox{}]
  ]

  def init do
    Enum.map(@default_settings, &SettingStore.put(&1, &2, [overwrite: false]))
  end

  def set? do
    SettingStore.set?(@default_settings)
  end

  def get do
    @default_settings
    |> Keyword.keys()
    |> SettingStore.get_by_keys()
  end

  def get(setting) do
    SettingStore.get(setting)
  end

  def get!(setting, key) do
    SettingStore.get!(setting, key)
  end

  def put(setting, value) do
    SettingStore.put(setting, value)
  end
end