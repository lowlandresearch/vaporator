defmodule Filesync.Supervisor do
  @moduledoc """
  Entry point for application
  
  Starts and supervises all of the application processes.

  Child Processes:
    - Client.EventMonitor.Supervisor
    - Client.EventProducer
    - Client.EventConsumer

  https://hexdocs.pm/elixir/Application.html`
  
  """
  use Supervisor

  alias Filesync.Client

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do

    children = [
      %{
        id: EventProducer,
        start: {
          Client.EventProducer,
          :start_link,
          [{:queue.new(), 0}]
        },
        type: :worker
      },
      %{
        id: EventConsumer,
        start: {
          Client.EventConsumer,
          :start_link,
          []
        },
        type: :supervisor
      },
      {Filesync.Cache, name: Filesync.Cache},
      %{
        id: Client.EventMonitor,
        start: {
          Client.EventMonitor,
          :start_link,
          [Client.sync_dirs]
        }
      }
    ]

   Supervisor.init(children, strategy: :one_for_one)
  end
end
