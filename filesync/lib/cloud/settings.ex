defmodule Filesync.Cloud.Settings do
  alias Filesync.Cloud.Dropbox

  defstruct [provider: %Dropbox{}]

  @table :cloud

  def set? do
    cloud = get()
    cloud.access_token != nil and cloud.root_path != nil
  end

  def get do
    SettingStore.get!(@table, :provider)
  end

  def put(value) do
    SettingStore.put(@table, value)
  end

  def put(provider, key, value) do
    setting = get()
    new_setting = Map.replace!(setting, key, value)

    SettingStore.put(
      @table,
      :provider,
      Map.merge(provider, new_setting)
    )
  end

end