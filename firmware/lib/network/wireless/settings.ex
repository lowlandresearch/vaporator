defmodule Firmware.Network.Wireless.Settings do
  defstruct ssid: nil, psk: nil, key_mgmt: :"NONE"

  @table :wireless

  def set? do
    wireless = get()
    wireless.ssid != nil
  end

  def get do
    SettingStore.get(@table)
  end

  def put(value) do
    SettingStore.put(@table, value)
  end
end