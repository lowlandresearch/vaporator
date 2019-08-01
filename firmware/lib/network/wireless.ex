defmodule Firmware.Network.Wireless do

  defstruct ssid: nil, psk: nil, key_mgmt: :"NONE"

  def setup(opts) do
    Nerves.Network.setup("wlan0", opts)
    SettingStore.put(:network, :wireless, opts)
  end

  def interface_up? do
    Firmware.Network.interface_up?("wlan0")
  end
end