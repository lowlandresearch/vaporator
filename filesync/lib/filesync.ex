defmodule Filesync do
  @moduledoc """
  Entry point for application

  Starts and supervises all of the application processes.

  Child Processes:
    - Client.EventMonitor.Supervisor
    - Client.EventProducer
    - Client.EventConsumer

  https://hexdocs.pm/elixir/Application.html`

  """
  use Application

  alias Filesync.Client

  def start(_args) do
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
          [[]]
        }
      },
      {Task, fn -> Filesync.Settings.init() end}
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: Filesync.Supervisor
    )
  end

end
