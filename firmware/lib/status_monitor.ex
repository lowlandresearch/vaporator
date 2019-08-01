defmodule Firmware.StatusMonitor do
  use GenServer

  require Logger

  alias Nerves.{Network, Leds}

  @interval 500

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Logger.info("Initializing #{__MODULE__}")

    Process.send_after(self(), :monitor, @interval)
    {:ok, state}
  end

  defp network_interface_up?(interface) do
    case Network.status(interface) do
      %{is_up: true, operstate: :down} -> false
      %{is_up: false} -> false
      _ -> true
    end
  end

  defp ethernet_interface_up? do
    network_interface_up?("eth0")
  end

  defp wireless_interface_up? do
    network_interface_up?("wlan0")
  end

  defp internet_reachable? do
    match?(
      {:ok, {:hostent, 'google.com', [], :inet, 4, _}},
      :inet_res.gethostbyname('google.com')
    )
  end

  defp filesync_settings_set? do
    client_settings_set?() and cloud_settings_set?()
  end

  defp client_settings_set? do
    client = SettingStore.get(:client)
    client.sync_dirs != []
  end

  defp cloud_settings_set? do
    cloud = SettingStore.get!(:cloud, :provider)
    cloud.access_token != nil and cloud.root_path != nil
  end

  @doc """
  Checks if all required settings are set for the system to run.
  
  Returns `boolean`
  """
  def system_settings_set? do
    filesync_settings_set?()
  end

  defp system_ok? do
    system_settings_set?()
    and ethernet_interface_up?()
    and wireless_interface_up?()
    and internet_reachable?()
  end

  @doc """
  Gets the current system status settings for Nerves.Leds

  Returns ```elixir
          [connected: true, alert: false]
          or
          [connected: false, alert: true]
          ```
  """
  def get_system_status do
    if system_ok?() do
      [connected: true, alert: false]
    else
      [connected: false, alert: true]
    end
  end

  # Server

  def handle_info(:monitor, _state) do

    status = get_system_status()

    Leds.set(status)

    Process.send_after(self(), :monitor, @interval)

    {:noreply, status}
  end

end