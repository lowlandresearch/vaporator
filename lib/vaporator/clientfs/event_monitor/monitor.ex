defmodule Vaporator.ClientFs.EventMonitor do
  @moduledoc """
  GenServer that spawns and subscribes to a file_system process to monitor
  :file_events for a local directory provided by the EventMonitor.Supervisor.
  When a :file_event is received, it is casted to ClientFs.EventProducer.
  """
  use GenServer
  require Logger

  def start_link(args) do
    Logger.info("#{__MODULE__} starting")
    GenServer.start_link(__MODULE__, args)
  end

  @doc """
  Initializes EventMonitor by completing initial_sync of all files that
  exist in the specified path to CloudFs and then start_maintenence for
  subsequent file event processing.

  https://hexdocs.pm/file_system/readme.html --> Example with GenServer
  """
  def init(args) do
    Logger.info("#{__MODULE__} initializing")
    initial_sync(args.path)
    start_maintenance(args.path)
    {:ok, :ready}
  end

  ############
  # API
  ###########

  @doc """
  Creates event tuple for use by EventProducer

  Args:
    path (binary): abspath on local file system

  Returns:
    event (tuple): EventProducer file_event
  """
  def create_event(path) do
    {:created, path}
  end

  @doc """
  Need to be able to sync a local folder with a cloud file system
  folder, making sure that all local files are uploaded to the cloud

  NOTE:
    This is the brute force approach by sending all files as
    created events.  The CloudFs rate limit could be reached,
    but this will be addressed with a RateLimiter later.

  Args:
    - path (binary): abspath on local file system to sync
    - file_regex (regex): Only file names matching the regex will be
       synced

  Returns:
    None
  """
  def initial_sync(path) do
    Logger.info("#{__MODULE__} STARTED INITIAL_SYNC of '#{path}'")
    path = Path.absname(path)

    case File.stat(path) do
      {:ok, %{access: access}} when access in [:read_write, :read] ->
        DirWalker.stream(path)
        |> Enum.map(&create_event/1)
        |> Enum.map(
          &Vaporator.ClientFs.EventProducer.enqueue/1
        )

      {:error, :enoent} ->
        {:error, :bad_local_path}
    end
    Logger.info("#{__MODULE__} COMPLETED INITIAL_SYNC of '#{path}'")
  end

  @doc """
  Starts maintenance monitoring of specified path

  Args:
    path (binary): abspath on local file system to sync

  Returns:
    None
  """
  def start_maintenance(path) do
    Logger.info("#{__MODULE__} ENTERING MAINTENANCE for '#{path}'")
    {:ok, pid} = FileSystem.start_link(
      dirs: path,
      recursive: true
    )

    FileSystem.subscribe(pid)
  end

  ############
  # SERVER
  ###########

  @doc """
  Receives :file_event from FileSystem subscribtion and sends
  it to EventProducer queue
  """
  def handle_info({:file_event, _, {path, [event]}}, state) do
    Logger.info(
      "#{__MODULE__} received an event | #{Atom.to_string(event)} -> `#{path}`"
    )
    Vaporator.ClientFs.EventProducer.enqueue({event, path})
    {:noreply, state}
  end
end
