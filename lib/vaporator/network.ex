defmodule Vaporator.Network do
  def maybe_start_wizard() do
    if should_start_wizard?(), do: VintageNetWizard.run_wizard()
  end

  defp should_start_wizard?() do
    wifi_configured?()
  end

  defp wifi_configured?() do
    VintageNet.get(["interface", "wlan0", "state"]) == :configured
  end
end
