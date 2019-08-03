defmodule Firmware.Monitor do
  use GenServer

  require Logger

  alias Firmware.Network

  @interval 5000

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Logger.info("Initializing #{__MODULE__}")

    Process.send_after(self(), :monitor, 500)
    {:ok, state}
  end

  @doc """
  Checks if all required settings are set for the system to run.

  Returns `boolean`
  """
  def system_settings_set? do
    Filesync.Settings.set?() and Firmware.Settings.set?()
  end

  defp system_ok? do
    system_settings_set?() and Network.up?()
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
    Nerves.Leds.set(status)
    Process.send_after(self(), :monitor, @interval)
    {:noreply, status}
  end
end
