defmodule Firmware.Network.Settings do
  alias Firmware.Network.Wireless

  def init do
    SettingStore.create(:wireless, %Wireless.Settings{})
  end

  def set? do
    Wireless.Settings.set?()
  end
end