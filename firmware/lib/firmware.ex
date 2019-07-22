defmodule Firmware do
  require Logger

  def start(_, _) do
    Logger.info("Starting Vaporator")
    {:ok, self()}
  end
end
