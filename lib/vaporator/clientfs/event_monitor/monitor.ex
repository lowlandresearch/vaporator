defmodule Vaporator.ClientFs.EventMonitor do
  @moduledoc """
  GenServer that spawns and subscribes to a file_system process to
  monitor :file_events for a local directory provided by the
  EventMonitor.Supervisor.  When a :file_event is received, it is
  cast to ClientFs.EventProducer.
  """
  use GenServer
  require Logger

  def start_link(paths) do
    Logger.info("#{__MODULE__} starting")
    GenServer.start_link(__MODULE__, paths, name: __MODULE__)
  end

  @doc """
  Initializes EventMonitor by completing initial_sync of all files
  that exist in the specified path to CloudFs and then
  start_maintenence for subsequent file event processing.

  https://hexdocs.pm/file_system/readme.html --> Example with GenServer
  """
  def init(paths) do
    Logger.info(
      "#{__MODULE__} initializing for:\n" <>
        "  paths: #{paths}"
    )
    paths
    |> Enum.map(&Vaporator.ClientFs.sync_directory/1)
    |> Enum.flat_map(
      fn outcome -> case outcome do
                      {:ok, path} -> [path]
                      _ -> []
                    end
      end
    )
    |> start_maintenance()
    # Enum.map(paths, &Vaporator.ClientFs.sync_directory/1)
    # start_maintenance(paths)
    {:ok, paths}
  end

  ############
  # API
  ###########

  @doc """
  Starts maintenance monitoring of specified path

  Args:
    path (binary): abspath on local file system to sync

  Returns:
    None
  """
  def start_maintenance(paths) do
    if not Enum.empty?(paths) do
      IO.inspect(paths)
      Logger.info(
        "#{__MODULE__} entering MAINTENANCE mode for:\n" <>
          "  paths: #{paths}"
      )
      
      {:ok, pid} = FileSystem.start_link(
        #dirs: paths |> Enum.map(fn path -> String.replace(path, " ", "\\ ") end)
        #dirs: paths |> Enum.map(fn path -> "\"#{path}\"" end)
        dirs: paths
      )
      FileSystem.subscribe(pid)
    else
      Logger.error(
        "#{__MODULE__} no paths given for MAINTENANCE mode"
      )
    end
  end

  ############
  # SERVER
  ###########

  @doc """
  Receives :file_event from FileSystem subscribtion and sends
  it to EventProducer queue
  """
  def handle_info({:file_event, _, {path, [event | _]}}, state) do
    case Vaporator.ClientFs.which_sync_dir(path) do
      {:ok, root} -> 
        Logger.info(
          "#{__MODULE__} received event | #{Atom.to_string(event)}..\n" <>
            "  root: #{root}" <>
            "  path: #{path}"
        )
        Vaporator.ClientFs.EventProducer.enqueue({event, {root, path}})
      :error ->
        Logger.error(
          "#{__MODULE__} received event | #{Atom.to_string(event)}.." <>
            "  could not find sync directory for path: #{path}"
        )
    end

    {:noreply, state}
  end
end
