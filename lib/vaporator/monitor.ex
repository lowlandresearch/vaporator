defmodule Vaporator.Monitor do
  @moduledoc """
  Monitors the system to ensure all required settings are set,
  internet is reachable, and has connectivity to host machines.
  """
  use GenServer

  require Logger

  alias Vaporator.Network

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
  Checks if the system is operational

  Returns `true` or `false`
  """
  def system_ok? do
    Vaporator.Settings.set?() and Network.up?()
  end

  @doc """
  Gets the current system status settings for Nerves.Leds

  Returns ```elixir
          [connected: true, alert: false]
          ```
          or
          ```elixir
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

  defp handle_info(:monitor, _state) do
    status = get_system_status()
    Nerves.Leds.set(status)
    Process.send_after(self(), :monitor, @interval)
    {:noreply, status}
  end
end
