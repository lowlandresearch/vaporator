defmodule Vaporator.ClientFs.EventMonitor do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: args.name)
  end

  def init(args) do
    {:ok, pid} = FileSystem.Worker.start_link(
                  dirs: args.path,
                  recursive: true
                )
    FileSystem.subscribe(pid)
    {:ok, pid}
  end

  def handle_info({:file_event, _, {path, [event]}}, state) do
    GenStage.cast(
      Vaporator.ClientFs.EventProducer,
      {:enqueue, {event, path}}
    )
    {:noreply, state}
  end
end