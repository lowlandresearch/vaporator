defmodule Vaporator.ClientFs.EventMonitor.Supervisor do
  @moduledoc """
  Supervises ClientFs.EventMonitors

  EventMonitors are created for each directory in the List of absolute
  paths returned by ClientFs.sync_dirs/0

  https://elixirschool.com/en/lessons/advanced/otp-supervisors/
  """
  use Supervisor
  require Logger

  def start_link do
    Logger.info("#{__MODULE__} starting")
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Initializes supervisor with one EventMonitor process per provided
  directory in ClientFs.sync_dirs/0
  """
  def init(:ok) do
    Logger.info("#{__MODULE__} initializing")

    children = [
      %{
        id: fs_watcher,
        start: {
          Sentix,
          :start_link,
          [
            :fs_watcher,
            Vaporator.ClientFs.sync_dirs,
            [monitor: "poll_monitor", recursive: true]
          ]
        }
      },
      %{
        id: ClientFs.EventMonitor,
        start: {
          Vaporator.ClientFs.EventMonitor,
          :start_link,
          [Vaporator.ClientFs.sync_dirs]
        }
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
