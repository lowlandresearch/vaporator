defmodule Vaporator.ClientFs do
  require Logger

  @moduledoc """
  Provides a single interface for:
    - Receiving events streamed from ClientFs and queues them into EventQueue
    - Processing events in EventQueue to determine necessary CloudFs sync action

  Events supported:
    - :created -> Uploads file to CloudFs
    - :modified -> Updates file in CloudFs
    - :deleted -> Removes file from CloudFs
  """

  @cloudfs %Vaporator.Dropbox{access_token: System.get_env("VAPORATOR_CLOUDFS_ACCESS_TOKEN")}
  @cloudfs_root Application.get_env(:vaporator, :cloudfs_root)

  @doc """
  Determines CloudFs sync action for the ClientFs generated event

  Args:
    - event (tuple): description of event action
                      i.e. {:created, filepath}
  """
  def process_event({:created, path}) do
    if not File.dir?(path) and File.exists?(path) do
      cloudfs_path = Vaporator.CloudFs.get_path(@cloudfs, path, @cloudfs_root)

      Vaporator.CloudFs.file_upload(
        @cloudfs,
        path,
        cloudfs_path
      )
    end
  end

  def process_event({:modified, path}) do
    if not File.dir?(path) and File.exists?(path) do
      cloudfs_path = Vaporator.CloudFs.get_path(@cloudfs, path, @cloudfs_root)

      Vaporator.CloudFs.file_update(
        @cloudfs,
        path,
        cloudfs_path
      )
    end
  end

  def process_event({:deleted, path}) do
    cloudfs_path = Vaporator.CloudFs.get_path(@cloudfs, path, @cloudfs_root)

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
  Retrieves environment variable VAPORATOR_SYNC_DIRS to convert
  the provided comma seperated string to a List

  Args:
    None

  Returns:
    sync_dirs (list): List of directories
  """
  def get_sync_dirs do
    Logger.info("#{__MODULE__} getting sync_dirs")

    case System.get_env("VAPORATOR_SYNC_DIRS") do
      nil ->
        Logger.error("VAPORATOR_SYNC_DIRS not set")
        []

      dirs ->
        Logger.info("#{__MODULE__} sync_dirs set")
        String.split(dirs, ",")
    end
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
  def sync_directory(path) do
    Logger.info("#{__MODULE__} STARTED INITIAL_SYNC of '#{path}'")

    path = Path.absname(path)

    case File.stat(path) do
      {:ok, %{access: access}} when access in [:read_write, :read] ->
        DirWalker.stream(path)
        |> Enum.map(fn x -> {:created, x} end)
        |> Enum.map(&Vaporator.ClientFs.EventProducer.enqueue/1)

      {:error, :enoent} ->
        {:error, :bad_local_path}
    end

    Logger.info("#{__MODULE__} COMPLETED INITIAL_SYNC of '#{path}'")
  end
end
