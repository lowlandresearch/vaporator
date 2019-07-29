defmodule Filesync.Client.EventConsumer do
  @moduledoc """
  GenStage ConsumerSupervisor that subscribes to EventProducer and spawns a
  Client.EventProcessor task process for each received event that updates
  Cloud.

  https://hexdocs.pm/gen_stage/ConsumerSupervisor.html
  """
  use ConsumerSupervisor
  require Logger

  def start_link do
    Logger.info("#{__MODULE__} starting")
    ConsumerSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_state) do
    Logger.info("#{__MODULE__} initializing")

    children = [
      %{
        id: Client.EventProcessor,
        start: {
          Filesync.Client.EventProcessor,
          :start_link,
          []
        },
        restart: :temporary
      }
    ]

    opts = [strategy: :one_for_one]

    GenStage.async_subscribe(
      __MODULE__,
      [
        to: Filesync.Client.EventProducer,
        max_demand: 2,          # until we can fix parallel upload
        min_demand: 1
      ]
    )

    ConsumerSupervisor.init(children, opts)
  end
end

defmodule Filesync.Client.EventProcessor do
  @moduledoc """
  Task that is spawned by EventConsumer whose only purpose is to
  call the required Client.process_event function to update Cloud
  https://hexdocs.pm/elixir/Task.html
  """

  @doc """
  Starts Task for Cloud update

  Task is started asychronously and then awaited.  Once the await returns,
  the task dies.

  Args:
    event (tuple): FileSystem event
                  i.e. {:created, {"/sync/path", "/sync/path/a.txt"}}

  """

  use Task
  require Logger

  def start_link(event) do
    {action, {root, path}} = event
    Logger.info(
      "#{__MODULE__} processing event | #{Atom.to_string(action)}\n" <>
        "  root: #{root}\n" <>
        "  path: #{path}"
    )

    Task.start_link(fn ->
      Filesync.Client.process_event(event)
    end)
  end
end
