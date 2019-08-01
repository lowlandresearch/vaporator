defmodule Firmware.Network.Ethernet do
  def interface_up? do
    Firmware.Network.interface_up?("eth0")
  end
end