defmodule Filesync.Settings do

  alias Filesync.{Client, Cloud}

  def init do
    SettingStore.create(:client, %Client.Settings{})
    SettingStore.create(:cloud, %Cloud.Settings{})
  end

  def set? do
    Client.Settings.set?() and Cloud.Settings.set?()
  end

  def get do
    %{
      client: Client.Settings.get(),
      cloud: Cloud.Settings.get()
    }
  end
end