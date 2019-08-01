defmodule Filesync.Client.EventMonitor do
  @moduledoc """
  GenServer that spawns and subscribes to a file_system process to
  monitor :file_events for a local directory provided by the
  EventMonitor.Supervisor.  When a :file_event is received, it is
  cast to Client.EventProducer.
  """
  use GenServer
  require Logger

  alias Filesync.{Client, Cloud, Cache, Cache.FileHashes}

  def start_link(paths) do
    Logger.info("#{__MODULE__} starting")
    GenServer.start_link(__MODULE__, paths, name: __MODULE__)
  end

  @doc """
  Initializes EventMonitor by completing initial_sync of all files
  that exist in the specified path to Cloud and then
  start_maintenence for subsequent file event processing.

  https://hexdocs.pm/file_system/readme.html --> Example with GenServer
  """
  def init(paths) do
    # Added to ensure module finishes initialization
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
    |> Enum.map(&cache_client/1)
    |> Enum.map(fn {:ok, path} -> path end)
    |> Enum.map(&cache_cloud/1)

    sync_files()

    poll_interval = SettingStore.get!(:client, :poll_interval)

    Process.sleep(poll_interval)

    paths = SettingStore.get!(:client, :sync_dirs)
    monitor(paths)
  end

  @doc """
  Checks for local file updates and syncs the changes to Cloud
  """
  def sync_files do

    Logger.info("#{__MODULE__} STARTED client and cloud sync")

    match_spec = [
      {{:"$1", %{client: :"$2", cloud: :"$3"}},
      [{:andalso, {:"/=", :"$2", :"$3"}, {:"/=", :"$2", nil}}],
      [:"$1"]}
    ]

    {:ok, records} = Cache.select(match_spec)

    records
    |> Enum.map(
          fn path ->
            {:created, {Client.which_sync_dir!(path), path}}
          end
        )
    |> Enum.map(&Client.EventProducer.enqueue/1)

    Logger.info("#{__MODULE__} COMPLETED client and cloud sync")
  end

  @doc """
  Updates Filesync.Cache with file hashes found in sync_dir

  Args:
    path (binary): absolute path of local fs

  Returns:
    result (tuple):
      {:ok, local_root} -> successful cache
      {:error, :bad_local_path} -> invalid directory
  """
  def cache_client(path) do
    local_root = Path.absname(path)

    cloud = SettingStore.get(:cloud)

    Logger.info("#{__MODULE__} STARTED client cache of '#{local_root}'")

    case File.stat(local_root) do
      {:ok, %{access: access}} when access in [:read_write, :read] ->
        DirWalker.stream(local_root)
        |> Enum.map(fn path ->
            hashes = Map.merge(
                        %FileHashes{},
                        %{client: Cloud.get_hash!(cloud.provider, path)}
                    )

            {path, hashes}
           end)
        |> Enum.map(&Cache.update/1)

        Logger.info("#{__MODULE__} COMPLETED client cache of '#{path}'")
        {:ok, local_root}

      {:error, :enoent} ->
        Logger.error("#{__MODULE__} bad local path in initial cache: '#{path}'")
        {:error, :bad_local_path}
    end
  end

  @doc """
  Updates Filesync.Cache with file hashes found in Cloud

  Args:
    path (binary): absolute path of local fs

  Returns:
    result (tuple):
      {:ok, local_root} -> successful cache
  """
  def cache_cloud(path) do

    cloud = SettingStore.get(:cloud)

    Logger.info("#{__MODULE__} STARTED cloud cache of '#{cloud.root_path}'")

    {:ok, %{results: meta}} = Cloud.list_folder(
                                cloud.provider,
                                Path.join(
                                  cloud.root_path,
                                  Path.basename(path)
                                ),
                                %{recursive: true}
                              )

    meta
    |> Enum.filter(fn %{type: t} -> t == :file end)
    |> Enum.map(fn %{path: p, meta: m} ->
        {
          Client.get_local_path!(cloud.root_path, p),
          %{cloud: m["content_hash"]}
        }
      end)
    |> Enum.map(&Cache.update/1)

    {:ok, cloud.root_path}

    Logger.info("#{__MODULE__} COMPLETED cloud cache of '#{cloud.root_path}'")
  end

  @doc """
  Starts the monitoring process
  """
  def handle_cast({:monitor, paths}, state) do
    {:noreply, monitor(paths), state}
  end

end
