defmodule Vaporator.Middleware do
 @moduledoc """
  Provides a single interface for:
    - Receiving events streamed from ClientFs and queues them into EventQueue
    - Processing events in EventQueue to determine necessary CloudFs sync action

  Events supported:
    - :created -> Uploads file to CloudFs
    - :modified -> Updates file in CloudFs
    - :removed -> Removes file from CloudFs
  """
  use GenServer
  require Logger

  @cloudfs %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}
  @cloudfs_path Application.get_env(:vaporator, :cloudfs_path)

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  #########
  # API
  #########

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

  def process_event({:removed, path}) do
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

  def process_event({:empty, reason}) do
    Logger.info("#{reason}")
  end

  def process_event({event, _}) do
    Logger.error("Unhandled event -> #{event}")
  end

  @doc """
  Processes next event in EventQueue
  """
  def process_next_event do
    GenServer.cast(__MODULE__, :process_next_event)
  end

  #########
  # Server
  #########

  @doc """
  Adds event to Vaporator.EventQueue

  Returns:
    :ok
  """
  def handle_cast({:queue_event, event}, state) do
      event |> Vaporator.EventQueue.enqueue
      {:noreply, state}
  end

  @doc """
  Gets next event in Vaporator.EventQueue and processes the event

  Returns:
    :ok
  """
  def handle_cast(:process_next_event, state) do
    Vaporator.EventQueue.dequeue |> process_event
    {:noreply, state}
  end

end
