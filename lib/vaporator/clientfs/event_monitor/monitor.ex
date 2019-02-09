defmodule Vaporator.ClientFs.EventMonitor do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: args.name)
  end

  @doc """
  Initializes EventMonitor by completing initial_sync of all files that
  exist in the specific path to CloudFs and then start_maintenence for
  subsequent file events
  """
  def init(args) do
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

  NOTE: This is the brute force approach by sending all files as
        created events.  The CloudFs rate limit could be reached,
        but this will be addressed with a RateLimiter later.

  Args:
    - local_root (binary): abspath on local file system to sync
    - file_regex (regex): Only file names matching the regex will be
       synced

  Returns:
    None
  """
  def initial_sync(local_root, file_regex \\ nil) do
    Logger.info("EventMonitor started INITIAL_SYNC of '#{local_root}'")
    local_root = Path.absname(local_root)

    case File.stat(local_root) do
      {:ok, %{access: access}} when access in [:read_write, :read] ->
        DirWalker.stream(
          local_root,
          matching: file_regex
        )
        |> Enum.map(&create_event/1)
        |> Enum.map(
          &Vaporator.ClientFs.EventProducer.enqueue/1
        )

      {:error, :enoent} ->
        {:error, :bad_local_path}
    end
    Logger.info("EventMonitor completed INITIAL_SYNC of '#{local_root}'")
  end

  @doc """
  Starts maintenance monitoring of specified path

  Args:
    path (binary): abspath on local file system to sync

  Returns:
    None
  """
  def start_maintenance(path) do
    Logger.info("EventMonitor entering MAINTENANCE for '#{path}'")
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
    # if event == :deleted do event = :removed end # For testing on Windows only
    Vaporator.ClientFs.EventProducer.enqueue({event, path})
    {:noreply, state}
  end
end
