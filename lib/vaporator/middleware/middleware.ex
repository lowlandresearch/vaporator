defmodule Vaporator.Middleware do
  use GenServer

  @cloudfs %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}
  @cloudfs_path Application.get_env(:vaporator, :cloudfs_path)

  def start_link do
    GenServer.start_link(__MODULE__, :queue.new, name: :middleware)
  end

  def init(queue) do
    {:ok, queue}
  end

  def handle_cast({:queue_event, event}, queue) do
    if not :queue.member(event, queue) do
      new_queue = :queue.in(event, queue)
      {:noreply, new_queue}
    else
      {:noreply, queue}
    end
  end

  def handle_cast(:process_next_event, queue) do
    if not :queue.is_empty(queue) do
      {{_, next_event}, new_queue} = :queue.out(queue)
      process_event(next_event)
      {:noreply, new_queue}
    else
      {:noreply, queue}
    end
  end

  def process_next_event do
    GenServer.cast(:middleware, :process_next_event)
  end

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

end
