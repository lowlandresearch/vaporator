defmodule Vaporator.ClientFs.EventMonitor.Supervisor do
  use Supervisor

  @sync_dirs System.get_env("VAPORATOR_SYNC_DIRS")

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    generate_children() |> Supervisor.init(strategy: :one_for_one)
  end

  @doc """
  Generates ClientFs children for configured watch directories.

  Returns:
    children (list): List of Vaporator.ClientFs child_specs
  """
  def generate_children do
    @sync_dirs
    |> String.split(",")
    # path needs to be a list for start_link
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
            path: path,
            name: generate_name(path)
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

  @doc """
  Generates a name for child_spec from the provided path
  Args:
    path (binary): absolute path for directory to be monitored

  Returns:
    name (atom): generated name (i.e. :clientfs_dropbox)

    NOTE: names cannot be strings
    https://hexdocs.pm/elixir/GenServer.html -> Name Registration
  """
  def generate_name(path) do
    path
    |> Path.basename()
    |> String.downcase()
    |> String.replace(" ", "")
    |> (fn x -> "event_monitor_#{x}" end).()
    |> String.to_atom()
  end
end
