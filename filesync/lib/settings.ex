defmodule Filesync.Settings do

  alias Filesync.Settings.{Client, Cloud}

  def init do
    SettingStore.create(:client, %Client{})
    SettingStore.create(:cloud, %Cloud{})
  end
end