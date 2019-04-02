defmodule Vaporator.ClientFs.EventMonitor do
  @moduledoc """
  GenServer that spawns and subscribes to a file_system process to
  monitor :file_events for a local directory provided by the
  EventMonitor.Supervisor.  When a :file_event is received, it is
  cast to ClientFs.EventProducer.
  """
  use GenServer
  require Logger

  @poll_interval Application.get_env(:vaporator, :poll_interval)

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
  def start(paths) do
    if not Enum.empty?(paths) do
      IO.inspect(paths)
      Logger.info(
        "#{__MODULE__} entering MAINTENANCE mode for:\n" <>
          "  paths: #{paths}"
      )

     monitor(paths)
    else
      Logger.error(
        "#{__MODULE__} no paths given for MAINTENANCE mode"
      )
    end
  end

  def monitor(paths) do
    paths
    |> Enum.map(&Vaporator.Sync.cache_clientfs/1)
    |> Enum.map(fn {:ok, path} -> path end)
    |> Enum.map(&Vaporator.Sync.cache_cloudfs/1)
    
    Vaporator.Sync.sync_files()

    Process.sleep(@poll_interval)
    monitor(paths)
  end

  def handle_cast(:monitor, paths) do
    monitor(paths)
  end

end
