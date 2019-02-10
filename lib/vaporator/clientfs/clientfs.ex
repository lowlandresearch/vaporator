defmodule Vaporator.ClientFs do
  require Logger

  @moduledoc """
  Provides a single interface for:
    - Receiving events streamed from ClientFs and queues them into EventQueue
    - Processing events in EventQueue to determine necessary CloudFs sync action

  Events supported:
    - :created -> Uploads file to CloudFs
    - :modified -> Updates file in CloudFs
    - :removed -> Removes file from CloudFs
  """

  @cloudfs %Vaporator.Dropbox{access_token: System.get_env("VAPORATOR_CLOUDFS_ACCESS_TOKEN")}
  @cloudfs_path System.get_env("VAPORATOR_CLOUDFS_PATH")

  @doc """
  Determines CloudFs sync action for the ClientFs generated event

  Args:
    - event (tuple): description of event action
                      i.e. {:created, filepath}
  """
  def process_event({:created, path}) do
    if File.exists?(path) do
      Vaporator.CloudFs.file_upload(
        @cloudfs,
        path,
        @cloudfs_path
      )
    end
  end

  def process_event({:modified, path}) do
    if File.exists?(path) do
      Vaporator.CloudFs.file_update(
        @cloudfs,
        path,
        Path.join(@cloudfs_path, Path.basename(path))
      )
    end
  end

  def process_event({:deleted, path}) do
    if File.dir?(path) do
      Vaporator.CloudFs.folder_remove(
        @cloudfs,
        Path.join(@cloudfs_path, Path.dirname("#[path}/"))
      )
    else
      Vaporator.CloudFs.file_remove(
        @cloudfs,
        Path.join(@cloudfs_path, Path.basename(path))
      )
    end
  end

  def process_event({event, _}) do
    Logger.error("Unhandled event -> #{event}")
  end

end
