defmodule Vaporator.Network.Wireless do
  @moduledoc """
  Manages Nerves.Network wireless interface.

  key_mgmt types: 
    - "WPA-PSK"
    - "NONE"
  """

  alias Vaporator.Settings

  @interface "wlan0"

  def init do
    if Settings.set?(:wireless) do
      opts = Settings.get!(:wireless)
      setup(opts)
    end
  end

  def setup(opts) do
    case Nerves.Network.setup(@interface, opts) do
      :ok ->
        Settings.put(:wireless, opts)
        {:ok, Keyword.fetch!(opts, :ssid)}

      _ ->
        {:error, :bad_settings}
    end
  end

  def scan do
    Nerves.Network.scan(@interface)
  end

  def up? do
    Vaporator.Network.interface_up?(@interface)
  end
end
