defmodule Vaporator.ClientFs.EventMonitor do
  @moduledoc """
  GenServer that spawns and subscribes to a file_system process to
  monitor :file_events for a local directory provided by the
  EventMonitor.Supervisor.  When a :file_event is received, it is
  cast to ClientFs.EventProducer.
  """
  use GenServer
  require Logger

  alias Vaporator.CloudFs
  alias Vaporator.ClientFs
  alias Vaporator.Cache

  @cloudfs %Vaporator.Dropbox{
    access_token: Application.get_env(:vaporator, :dbx_token)
  }
  @cloudfs_root Application.get_env(:vaporator, :cloudfs_root)
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

    GenServer.cast(__MODULE__, {:monitor, paths})
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
  def monitor(paths) do
    paths
    |> Enum.map(&cache_clientfs/1)
    |> Enum.map(fn {:ok, path} -> path end)
    |> Enum.map(&cache_cloudfs/1)

    sync_files()

    Process.sleep(@poll_interval)
    monitor(paths)
  end

  @doc """
  Checks for local file updates and syncs the changes to CloudFs
  """
  def sync_files do

    Logger.info("#{__MODULE__} STARTED clientfs and cloudfs sync")

    match_spec = [
      {{:"$1", %{clientfs: :"$2", cloudfs: :"$3"}},
      [{:andalso, {:"/=", :"$2", :"$3"}, {:"/=", :"$2", nil}}],
      [:"$1"]}
    ]

    {:ok, records} = Cache.select(match_spec)

    records
    |> Enum.map(
          fn path ->
            {:created, {ClientFs.which_sync_dir!(path), path}}
          end
        )
    |> Enum.map(&ClientFs.EventProducer.enqueue/1)

    Logger.info("#{__MODULE__} COMPLETED clientfs and cloudfs sync")
  end

  @doc """
  Updates Vaporator.Cache with file hashes found in sync_dir

  Args:
    path (binary): absolute path of local fs

  Returns:
    result (tuple):
      {:ok, local_root} -> successful cache
      {:error, :bad_local_path} -> invalid directory
  """
  def cache_clientfs(path) do
    local_root = Path.absname(path)

    Logger.info("#{__MODULE__} STARTED clientfs cache of '#{local_root}'")

    case File.stat(local_root) do
      {:ok, %{access: access}} when access in [:read_write, :read] ->
        DirWalker.stream(local_root)
        |> Enum.map(fn path ->
            hashes = Map.merge(
                        %FileHashes{},
                        %{clientfs: CloudFs.get_hash!(@cloudfs, path)}
                    )

            {path, hashes}
           end)
        |> Enum.map(&Cache.update/1)

        Logger.info("#{__MODULE__} COMPLETED clientfs cache of '#{path}'")
        {:ok, local_root}

      {:error, :enoent} ->
        Logger.error("#{__MODULE__} bad local path in initial cache: '#{path}'")
        {:error, :bad_local_path}
    end
  end

  @doc """
  Updates Vaporator.Cache with file hashes found in CloudFs

  Args:
    path (binary): absolute path of local fs

  Returns:
    result (tuple):
      {:ok, local_root} -> successful cache
  """
  def cache_cloudfs(path) do

    Logger.info("#{__MODULE__} STARTED cloudfs cache of '#{@cloudfs_root}'")

    {:ok, %{results: meta}} = CloudFs.list_folder(
                                @cloudfs,
                                Path.join(
                                  @cloudfs_root,
                                  Path.basename(path)
                                ),
                                %{recursive: true}
                              )

    meta
    |> Enum.filter(fn %{type: t} -> t == :file end)
    |> Enum.map(fn %{path: p, meta: m} ->
        {
          ClientFs.get_local_path!(@cloudfs_root, p),
          %{cloudfs: m["content_hash"]}
        }
      end)
    |> Enum.map(&Cache.update/1)

    {:ok, @cloudfs_root}

    Logger.info("#{__MODULE__} COMPLETED cloudfs cache of '#{@cloudfs_root}'")
  end

  def handle_cast({:monitor, paths}, state) do
    {:noreply, monitor(paths), state}
  end

end
