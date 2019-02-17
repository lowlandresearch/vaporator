defmodule Vaporator.ClientFs.EventMonitor.Supervisor do
  @moduledoc """
  Supervises ClientFs.EventMonitors

  EventMonitors are created for each directory found in the environment
  variable VAPORATOR_SYNC_DIRS that is a comma seperated list of absolute
  paths.

  i.e. VAPORATOR_SYNC_DIRS="/c/vaporator/dropbox,/c/vaporator/onedrive"

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
  directory in VAPORATOR_SYNC_DIRS environment variable
  """
  def init(:ok) do
    Logger.info("#{__MODULE__} initializing")

    children = [
      %{
        id: ClientFs.EventMonitor,
        start: {
          Vaporator.ClientFs.EventMonitor,
          :start_link,
          [Vaporator.ClientFs.get_sync_dirs()]
        }
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
