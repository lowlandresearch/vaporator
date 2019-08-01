defmodule Firmware.Settings do

  alias Firmware.Network

  def init do
    Network.Settings.init()
  end

  def set? do
    Network.Settings.set?()
  end
end