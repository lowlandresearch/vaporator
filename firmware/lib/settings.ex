defmodule Firmware.Settings do

  alias Firmware.Network.Wireless

  def init do
    SettingStore.create(:network, %Wireless{})
  end
end