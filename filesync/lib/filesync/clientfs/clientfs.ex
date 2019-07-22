defmodule Filesync.ClientFs do
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
    - :removed -> Removes file from CloudFs
  """

  @cloudfs %Filesync.Dropbox{
    access_token: Application.get_env(:filesync, :dbx_token)
  }
  @cloudfs_root Application.get_env(:filesync, :cloudfs_root)

  @doc """
  Determines CloudFs sync action for the ClientFs generated event

  Args:
    - event (tuple): description of event action
                      i.e. {:created, filepath}
  """
  def process_event({:created, {root, path}}) do
    if not File.dir?(path) and File.exists?(path) do
      cloudfs_path = Filesync.CloudFs.get_path(
        @cloudfs, root, path, @cloudfs_root
      )
      Logger.info(
        "#{__MODULE__} CREATED event:\n" <>
          "  local path: #{path}\n" <>
          "  cloud path: #{cloudfs_path}"
      )

      case Filesync.CloudFs.file_upload(
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
      cloudfs_path = Filesync.CloudFs.get_path(
        @cloudfs, root, path, @cloudfs_root
      )
      Logger.info("#{__MODULE__} MODIFIED event:\n" <>
        "  local path: #{path}\n" <>
        "  cloud path: #{cloudfs_path}"
      )

      case Filesync.CloudFs.file_update(
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

  def process_event({:removed, {root, path}}) do
    cloudfs_path = Filesync.CloudFs.get_path(
      @cloudfs, root, path, @cloudfs_root
    )
    Logger.info("#{__MODULE__} DELETED event:\n" <>
      "  local path: #{path}\n" <>
      "  cloud path: #{cloudfs_path}"
    )

    if File.dir?(path) do
      Filesync.CloudFs.folder_remove(
        @cloudfs,
        cloudfs_path
      )
    else
      Filesync.CloudFs.file_remove(
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

    case Application.get_env(:filesync, :clientfs_sync_dirs) do
      nil ->
        Logger.error(":clientfs_sync_dirs NOT configured")
        []

      dirs ->
        dirs
    end
  end

  @doc """
  To which sync directory does this path belong?

  Args:
    - path (binary): 
  """
  def which_sync_dir!(path) do
    sync_dirs()
    |> Enum.filter(
      fn root -> String.starts_with?(path, root) end
    )
    |> Enum.fetch!(0)
  end

  @doc """
  Given a cloudfs_root, the cloudfs_path within it, and a local_root, what
  is the local_path?
  """
  def get_local_path!(cloudfs_root, cloudfs_path) do
    path = Path.relative_to(
              cloudfs_path |> Path.absname,
              cloudfs_root |> Path.absname
            )


    path_root = path
                |> Path.split()
                |> List.first()

    sync_dirs()
    |> Enum.filter(fn x ->
        String.ends_with?(x, path_root)
      end)
    |> Path.dirname()
    |> Path.join(path)
  end

end
