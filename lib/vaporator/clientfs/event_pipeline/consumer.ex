defmodule Vaporator.ClientFs.EventConsumer do
  @moduledoc """
  GenStage ConsumerSupervisor that subscribes to EventProducer and spawns
  a task process for each received event that updates CloudFs
  https://hexdocs.pm/gen_stage/ConsumerSupervisor.html
  """
  use ConsumerSupervisor

  def start_link(state) do
    ConsumerSupervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_state) do
    children = [
      %{
        id: ClientFs.EventProcessor,
        start: {
          Vaporator.ClientFs.EventProcessor,
          :start_link,
          []
        },
        restart: :temporary
      }
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [
        {
          Vaporator.ClientFs.EventProducer,
          max_demand: 5, min_demand: 3
        }
      ]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end

defmodule Vaporator.ClientFs.EventProcessor do
  @moduledoc """
  Task that is spawned by EventConsumer whose only purpose is to
  call the required ClientFs.process_event function to update CloudFs
  https://hexdocs.pm/elixir/Task.html
  """

  @doc """
  Starts Task for CloudFs update

  Task is started asychronously and then awaited.  Once the await returns,
  the task dies.

  Args:
    event (tuple): FileSystem event
                  i.e. {:created, "/path/a.txt"}

  """
  def start_link(event) do
    Task.start_link(fn ->
      Vaporator.ClientFs.process_event(event)
    end)
  end
end
