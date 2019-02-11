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
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Initializes supervisor with one EventMonitor process per provided
  directory in VAPORATOR_SYNC_DIRS environment variable
  """
  def init(:ok) do
    get_sync_dirs()
    |> generate_children()
    |> Supervisor.init(strategy: :one_for_one)
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
    case System.get_env("VAPORATOR_SYNC_DIRS") do
      nil ->
        Logger.error("VAPORATOR_SYNC_DIRS not set")
        []
      dirs -> String.split(dirs, ",")
    end
  end

  @doc """
  Generates ClientFs.EventMonitors child_specs for configured watch
  directories.

  Args:
    dirs (list): List of directories

  Returns:
    child_specs (list): List of Vaporator.ClientFs.EventMonitor
  """
  def generate_children(dirs) do
    dirs
    |> Enum.map(fn x -> [x] end)
    |> Enum.map(&child_spec/1)
  end

  @doc """
  Creates a map for a EventMonitor process spec

  elixirschool.com/en/lessons/advanced/otp-supervisors/#child-specification

  Args:
    path (binary): absolute path for directory to be monitored

  Returns:
    child_spec (map)
  """
  def child_spec(path) do
    %{
      id: generate_id(path),
      start: {
        Vaporator.ClientFs.EventMonitor,
        :start_link,
        [
          %{
            path: path
          }
        ]
      }
    }
  end

  @doc """
  Generates an id for child_spec from hash of the provided path

  Args:
    path (binary): absolute path for directory to be monitored

  Returns:
    id (binary): hash of provided path
  """
  def generate_id(path) do
    :crypto.hash(:sha256, path)
    |> Base.encode16()
    |> String.downcase()
  end
end
