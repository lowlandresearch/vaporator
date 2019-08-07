defmodule Vaporator.Client do
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

  alias Vaporator.Settings

  require Logger

  def set_poll_interval(interval) when is_integer(interval) do
    if interval < 10000 do
      {:error, "interval must be >= 10 seconds"}
    else
      Settings.put(:poll_interval, interval)
    end
  end

  def set_poll_interval(_) do
    {:error, "interval must be an integer"}
  end

  def add_sync_dir(path) do
    setting = Settings.get(:sync_dirs)
    Settings.put(:sync_dirs, [path | setting])
  end

  def remove_sync_dir(path) do
    setting = Settings
    new_setting = List.delete(setting, path)
    Settings.put(:sync_dirs, new_setting)
  end

  @doc """
  Determines Cloud sync action for the Client generated event

  Args:
    - event (tuple): description of event action
                      i.e. {:created, filepath}
  """
  def process_event({:created, {root, path}}) do
    if not File.dir?(path) and File.exists?(path) do
      cloud = Settings.get(:cloud)

      cloud_path =
        Vaporator.Cloud.get_path(
          cloud.provider,
          root,
          path,
          cloud.provider.root_path
        )

      Logger.info(
        "#{__MODULE__} CREATED event:\n" <>
          "  local path: #{path}\n" <>
          "  cloud path: #{cloud_path}"
      )

      case Vaporator.Cloud.file_upload(
             cloud.provider,
             path,
             cloud_path
           ) do
        {:ok, meta} ->
          Logger.info("#{__MODULE__} upload SUCCESS.")
          {:ok, meta}

        {:error, reason} ->
          Logger.error("#{__MODULE__} upload FAILURE: #{reason}")
          {:error, reason}
      end
    end
  end

  def process_event({:updated, {root, path}}) do
    if not File.dir?(path) and File.exists?(path) do
      cloud = Settings.get(:cloud)

      cloud_path =
        Vaporator.Cloud.get_path(
          cloud.provider,
          root,
          path,
          cloud.provider.root_path
        )

      Logger.info(
        "#{__MODULE__} MODIFIED event:\n" <>
          "  local path: #{path}\n" <>
          "  cloud path: #{cloud_path}"
      )

      case Vaporator.Cloud.file_update(
             cloud.provider,
             path,
             cloud_path
           ) do
        {:ok, meta} ->
          Logger.info("#{__MODULE__} update SUCCESS.")
          {:ok, meta}

        {:error, reason} ->
          Logger.error("#{__MODULE__} update FAILURE: #{reason}")
          {:error, reason}
      end
    end
  end

  def process_event({:removed, {root, path}}) do
    cloud = Settings.get(:cloud)

    cloud_path =
      Vaporator.Cloud.get_path(
        cloud.provider,
        root,
        path,
        cloud.provider.root_path
      )

    Logger.info(
      "#{__MODULE__} DELETED event:\n" <>
        "  local path: #{path}\n" <>
        "  cloud path: #{cloud_path}"
    )

    if File.dir?(path) do
      Vaporator.Cloud.folder_remove(
        cloud.provider,
        cloud_path
      )
    else
      Vaporator.Cloud.file_remove(
        cloud.provider,
        cloud_path
      )
    end
  end

  def process_event({event, _}) do
    Logger.error("#{__MODULE__} unhandled event -> #{event}")
  end

  @doc """
  To which sync directory does this path belong?

  Args:
    - path (binary): 
  """
  def which_sync_dir!(path) do
    sync_dirs = Settings.get!(:client, :sync_dirs)

    sync_dirs
    |> Enum.filter(fn root -> String.starts_with?(path, root) end)
    |> Enum.fetch!(0)
  end

  @doc """
  Given a cloud_root, the cloud_path within it, and a local_root, what
  is the local_path?
  """
  def get_local_path!(cloud_root, cloud_path) do
    path =
      Path.relative_to(
        cloud_path |> Path.absname(),
        cloud_root |> Path.absname()
      )

    path_root =
      path
      |> Path.split()
      |> List.first()

    sync_dirs = Settings.get!(:client, :sync_dirs)

    sync_dirs
    |> Enum.filter(fn x ->
      String.ends_with?(x, path_root)
    end)
    |> Path.dirname()
    |> Path.join(path)
  end
end
