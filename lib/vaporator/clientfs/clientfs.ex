defmodule Vaporator.ClientFs do
  require Logger

  @moduledoc """
  Provides a single interface for:
    - Receiving events streamed from ClientFs and queues them into
      EventQueue
    - Processing events in EventQueue to determine necessary CloudFs
      sync action

  Events supported:
    - :created -> Uploads file to CloudFs
    - :updated -> Updates file in CloudFs
    - :deleted -> Removes file from CloudFs
  """

  @cloudfs %Vaporator.Dropbox{
    access_token: Application.get_env(:vaporator, :dbx_token)
  }
  @cloudfs_root Application.get_env(:vaporator, :cloudfs_root)

  @doc """
  Determines CloudFs sync action for the ClientFs generated event

  Args:
    - event (tuple): description of event action
                      i.e. {:created, filepath}
  """
  def process_event({:created, {root, path}}) do
    if not File.dir?(path) and File.exists?(path) do
      cloudfs_path = Vaporator.CloudFs.get_path(
        @cloudfs, root, path, @cloudfs_root
      )
      Logger.info(
        "#{__MODULE__} CREATED event:\n" <>
          "  local path: #{path}\n" <>
          "  cloud path: #{cloudfs_path}"
      )

      case Vaporator.CloudFs.file_upload(
            @cloudfs,
            path,
            cloudfs_path
          ) do
        {:ok, meta} ->
          Logger.info(
            "#{__MODULE__} upload SUCCESS."
          )
          {:ok, meta}
        {:error, reason} ->
          Logger.error(
            "#{__MODULE__} upload FAILURE: #{reason}"
          )
          {:error, reason}
      end
    end
  end

  def process_event({:updated, {root, path}}) do
    if not File.dir?(path) and File.exists?(path) do
      cloudfs_path = Vaporator.CloudFs.get_path(
        @cloudfs, root, path, @cloudfs_root
      )
      Logger.info("#{__MODULE__} MODIFIED event:\n" <>
        "  local path: #{path}\n" <>
        "  cloud path: #{cloudfs_path}"
      )

      case Vaporator.CloudFs.file_update(
            @cloudfs,
            path,
            cloudfs_path
          ) do
        {:ok, meta} ->
          Logger.info(
            "#{__MODULE__} update SUCCESS."
          )
          {:ok, meta}
        {:error, reason} ->
          Logger.error(
            "#{__MODULE__} update FAILURE: #{reason}"
          )
          {:error, reason}
      end
    end
  end

  def process_event({:deleted, {root, path}}) do
    cloudfs_path = Vaporator.CloudFs.get_path(
      @cloudfs, root, path, @cloudfs_root
    )
    Logger.info("#{__MODULE__} DELETED event:\n" <>
      "  local path: #{path}\n" <>
      "  cloud path: #{cloudfs_path}"
    )

    if File.dir?(path) do
      Vaporator.CloudFs.folder_remove(
        @cloudfs,
        cloudfs_path
      )
    else
      Vaporator.CloudFs.file_remove(
        @cloudfs,
        cloudfs_path
      )
    end
  end

  def process_event({event, _}) do
    Logger.error("#{__MODULE__} unhandled event -> #{event}")
  end

  @doc """
  Currently, retrieves List of absolute paths from Application
  variable :clientfs_sync_dirs.

  TODO: pull these from a runtime configuration database of some sort.

  Args:
    None

  Returns:
    sync_dirs (list): List of absolute paths to directories
  """
  def sync_dirs do
    Logger.info("#{__MODULE__} getting sync_dirs")

    case Application.get_env(:vaporator, :clientfs_sync_dirs) do
      nil ->
        Logger.error(":clientfs_sync_dirs NOT configured")
        []

      dirs ->
        Logger.info("#{__MODULE__} sync_dirs set: #{dirs}")
        dirs
    end
  end

  @doc """
  To which sync directory does this path belong?

  Args:
    - path (binary): 
  """
  def which_sync_dir(path) do
    sync_dirs()
    |> Enum.filter(
      fn root -> String.starts_with?(path, root) end
    )
    |> Enum.fetch(0)
  end

  @doc """
  Need to be able to sync a local folder with a cloud file system
  folder, making sure that all local files are uploaded to the cloud

  NOTE:
    This is the brute force approach by sending all files as created
    events.  The CloudFs rate limit could be reached, but this will be
    addressed with a RateLimiter later.

  Args:
    - path (binary): abspath on local file system to sync
    - file_regex (regex): Only file names matching the regex will be
       synced

  Returns:
    None
  """
  def sync_directory(path) do
    local_root = Path.absname(path)

    Logger.info("#{__MODULE__} STARTED initial sync of '#{local_root}'")

    case File.stat(local_root) do
      {:ok, %{access: access}} when access in [:read_write, :read] ->
        DirWalker.stream(local_root)
        |> Enum.map(
          fn path ->
            {:created, {local_root, path}}
          end
        )
        |> Enum.map(&Vaporator.ClientFs.EventProducer.enqueue/1)

        Logger.info("#{__MODULE__} COMPLETED initial sync of '#{path}'")
        {:ok, local_root}
      {:error, :enoent} ->
        Logger.error("#{__MODULE__} bad local path in initial sync: '#{path}'")
        {:error, :bad_local_path}
    end
  end
end
