defmodule Vaporator.ClientFs.EventMonitor.Supervisor do
  @moduledoc """
  Supervises ClientFs.EventMonitors

  EventMonitors are created for each directory found in the environment variable
  VAPORATOR_SYNC_DIRS that is a comma seperated list of absolute paths.

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
          [get_sync_dirs()]
        }
      }
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Retrieves environment variable VAPORATOR_SYNC_DIRS to convert
  the provided comma seperated string to a List

  Args:
    None
  
  Returns:
    sync_dirs (list): List of directories
  """
  def get_sync_dirs do
    Logger.info("#{__MODULE__} getting sync_dirs")
    case System.get_env("VAPORATOR_SYNC_DIRS") do
      nil ->
        Logger.error("VAPORATOR_SYNC_DIRS not set")
        []
      dirs ->
        Logger.info("#{__MODULE__} sync_dirs set")
        String.split(dirs, ",")
    end
  end
end
