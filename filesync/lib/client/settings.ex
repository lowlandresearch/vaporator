defmodule Filesync.Client.Settings do
  defstruct sync_dirs: [], poll_interval: 30000

  @table :client

  def set? do
    client = get()
    client.sync_dirs != []
  end

  def get do
    SettingStore.get(@table)
  end

  def get(key) do
    SettingStore.get!(@table, key)
  end

  def put(value) do
    SettingStore.put(@table, value)
  end

  def put(key, value) do
    SettingStore.put(@table, key, value)
  end
end