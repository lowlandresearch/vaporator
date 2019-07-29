defmodule Filesync.Client do
  require Logger

  @moduledoc """
  Provides a single interface for:
    - Receiving events streamed from Client and queues them into
      EventQueue
    - Processing events in EventQueue to determine necessary Cloud
      sync action

  Events supported:
    - :created -> Uploads file to Cloud
    - :updated -> Updates file in Cloud
    - :removed -> Removes file from Cloud
  """

  @cloud %FileSync.Cloud.Dropbox{
    access_token: Application.get_env(:filesync, :dbx_token)
  }
  @cloud_root Application.get_env(:filesync, :cloud_root)

  @doc """
  Determines Cloud sync action for the Client generated event

  Args:
    - event (tuple): description of event action
                      i.e. {:created, filepath}
  """
  def process_event({:created, {root, path}}) do
    if not File.dir?(path) and File.exists?(path) do
      cloud_path = Filesync.Cloud.get_path(
        @cloud, root, path, @cloud_root
      )
      Logger.info(
        "#{__MODULE__} CREATED event:\n" <>
          "  local path: #{path}\n" <>
          "  cloud path: #{cloud_path}"
      )

      case Filesync.Cloud.file_upload(
            @cloud,
            path,
            cloud_path
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
      cloud_path = Filesync.Cloud.get_path(
        @cloud, root, path, @cloud_root
      )
      Logger.info("#{__MODULE__} MODIFIED event:\n" <>
        "  local path: #{path}\n" <>
        "  cloud path: #{cloud_path}"
      )

      case Filesync.Cloud.file_update(
            @cloud,
            path,
            cloud_path
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
    cloud_path = Filesync.Cloud.get_path(
      @cloud, root, path, @cloud_root
    )
    Logger.info("#{__MODULE__} DELETED event:\n" <>
      "  local path: #{path}\n" <>
      "  cloud path: #{cloud_path}"
    )

    if File.dir?(path) do
      Filesync.Cloud.folder_remove(
        @cloud,
        cloud_path
      )
    else
      Filesync.Cloud.file_remove(
        @cloud,
        cloud_path
      )
    end
  end

  def process_event({event, _}) do
    Logger.error("#{__MODULE__} unhandled event -> #{event}")
  end

  @doc """
  Currently, retrieves List of absolute paths from Application
  variable :client_sync_dirs.

  TODO: pull these from a runtime configuration database of some sort.

  Args:
    None

  Returns:
    sync_dirs (list): List of absolute paths to directories
  """
  def sync_dirs do

    case Application.get_env(:filesync, :client_sync_dirs) do
      nil ->
        Logger.error(":client_sync_dirs NOT configured")
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
  Given a cloud_root, the cloud_path within it, and a local_root, what
  is the local_path?
  """
  def get_local_path!(cloud_root, cloud_path) do
    path = Path.relative_to(
              cloud_path |> Path.absname,
              cloud_root |> Path.absname
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
