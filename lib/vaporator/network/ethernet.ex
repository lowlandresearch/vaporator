defmodule Vaporator.Network.Ethernet do
  def up? do
    Vaporator.Network.interface_up?("eth0")
  end
end
