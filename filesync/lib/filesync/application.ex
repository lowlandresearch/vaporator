defmodule Filesync do
  @moduledoc """
  Entry point for application
  
  Starts and supervises all of the application processes.

  Child Processes:
    - ClientFs.EventMonitor.Supervisor
    - ClientFs.EventProducer
    - ClientFs.EventConsumer

  https://hexdocs.pm/elixir/Application.html`
  
  """
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info(
      "#{__MODULE__} starting...\n" <>
        "  env: #{Mix.env}"
    )

    children = [
      %{
        id: EventProducer,
        start: {
          Filesync.ClientFs.EventProducer,
          :start_link,
          [{:queue.new(), 0}]
        },
        type: :worker
      },
      %{
        id: EventConsumer,
        start: {
          Filesync.ClientFs.EventConsumer,
          :start_link,
          []
        },
        type: :supervisor
      },
      {Filesync.Cache, name: Filesync.Cache},
      %{
        id: ClientFs.EventMonitor,
        start: {
          Filesync.ClientFs.EventMonitor,
          :start_link,
          [Filesync.ClientFs.sync_dirs]
        }
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Filesync.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
