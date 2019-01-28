defmodule Vaporator.ClientFs do
  use GenServer

  @cloudfs %Vaporator.Dropbox{access_token: System.get_env("DROPBOX_ACCESS_TOKEN")}
  @clientfs_path Application.get_env(:vaporator, :clientfs_path)
  @cloudfs_path Application.get_env(:vaporator, :cloudfs_path)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    {:ok, pid} = FileSystem.start_link(
      dirs: [@clientfs_path],
      recursive: true
    )
    FileSystem.subscribe(pid)
    {:ok, %{watcher_pid: pid}}
  end

  def handle_info({:file_event, _, {local_path, [event]}}, state) do
    process_event(event, local_path, @cloudfs)
    {:noreply, state}
  end

  def handle_info({:file_event, _, :stop}, state) do
    {:noreply, state}
  end

  defp process_event(:created, local_path, cloudfs) do
    IO.puts("Created -> #{local_path}")
    Vaporator.CloudFs.file_upload(
      cloudfs, local_path, @cloudfs_path
    )
  end

  defp process_event(:modified, local_path, cloudfs) do
    # Creation events also trigger a Modified event
    # Checking if created and modified time are the same
    # to determine if cloudfs needs to be updated
    stats = File.lstat!(local_path)
    modified_event? = stats.ctime == stats.atime
    if not modified_event? do
      IO.puts("Modified -> #{local_path}")
      Vaporator.CloudFs.file_update(
        cloudfs,
        local_path,
        "#{@cloudfs_path}#{Path.basename(local_path)}"
      )
    end
  end

  defp process_event(:renamed, local_path, _cloudfs) do
    IO.puts("Renamed -> #{local_path}")
    # TODO: Figure out how to rename files in CloudFs
    # Currently depend on local_path.basename to know which
    # file to update in CloudFs
  end

  defp process_event(:removed, local_path, cloudfs) do
    IO.puts("Deleted -> #{local_path}")
    case File.dir?(local_path) do
      true ->
        Vaporator.CloudFs.folder_remove(cloudfs, local_path)
      false ->
        Vaporator.CloudFs.file_remove(cloudfs, local_path)
    end
  end

  defp process_event(event, _local_path, _cloudfs) do
    {:error, {:unhandled_event, event}}
  end

end