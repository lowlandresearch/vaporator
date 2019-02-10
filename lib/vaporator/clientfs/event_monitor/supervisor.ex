defmodule Vaporator.ClientFs.EventMonitor.Supervisor do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    get_sync_dirs()
    |> generate_children()
    |> Supervisor.init(strategy: :one_for_one)
  end

  def get_sync_dirs do
    case System.get_env("VAPORATOR_SYNC_DIRS") do
      nil ->
        Logger.error("VAPORATOR_SYNC_DIRS not set")
        []
      dirs -> String.split(dirs, ",")
    end
  end

  @doc """
  Generates ClientFs children for configured watch directories.

  Returns:
    children (list): List of Vaporator.ClientFs child_specs
  """
  def generate_children(dirs) do
    dirs
    |> Enum.map(fn x -> [x] end)
    |> Enum.map(&child_spec/1)
  end

  @doc """
  Creates a map for a EventMonitor process spec
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
  Generates an id for child_spec from the provided path
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
