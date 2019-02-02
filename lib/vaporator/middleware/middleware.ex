defmodule Vaporator.Middleware do
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

  # API

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

  def process_next_event do
    GenServer.cast(__MODULE__, :process_next_event)
  end

  # Server

  def handle_cast({:queue_event, event}, state) do
      event |> Vaporator.EventQueue.enqueue
      {:noreply, state}
  end

  def handle_cast(:process_next_event, state) do
    Vaporator.EventQueue.dequeue |> process_event
    {:noreply, state}
  end

end
