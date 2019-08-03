defmodule Firmware.Network.Ethernet do
  def up? do
    Firmware.Network.interface_up?("eth0")
  end
end
