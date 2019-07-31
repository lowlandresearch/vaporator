defmodule Firmware.StatusMonitor do
  use GenServer

  require Logger

  alias Nerves.Network

  @interval 500

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Logger.info("Initializing #{__MODULE__}")

    Process.send_after(self(), :monitor, @interval)
    {:ok, state}
  end

  defp wireless_interface_up? do
    case Network.status("wlan") do
      %{is_up: true, operstate: :down} -> false
      %{is_up: false} -> false
      _ -> true
    end
  end

  defp internet_reachable? do
    match?(
      {:ok, {:hostent, 'google.com', [], :inet, 4, _}},
      :inet_res.gethostbyname('google.com')
    )
  end

  defp all_settings_present? do
    filesync_settings_set?() and cloud_settings_set?()
  end

  defp filesync_settings_set? do
    client = SettingStore.get(:client)
    client.sync_dirs != []
  end

  defp cloud_settings_set? do
    cloud = SettingStore.get!(:cloud, :provider)
    cloud.access_token != nil and cloud.root_path != nil
  end

  # Server

  def handle_info(:monitor, state) do
    ok? =
      all_settings_present?()
      and wireless_interface_up?()
      and internet_reachable?()

    Nerves.Leds.set(connected: ok?, alert: not ok?)

    Process.send_after(self(), :monitor, @interval)

    {:noreply, state}
  end

end