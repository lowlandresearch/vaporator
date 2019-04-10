defmodule Vaporator do
  @moduledoc """
  Entry point for application
  
  Starts and supervises all of the application processes.

  Child Processes:
    - ClientFs.EventMonitor.Supervisor
    - ClientFs.EventProducer
    - ClientFs.EventConsumer

  https://hexdocs.pm/elixir/Application.html
  
  """
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info(
      "#{__MODULE__} starting...\n" <>
        "  type: #{type}\n" <>
        "  args: #{args}\n" <>
        "  env: #{Mix.env}"
    )

    children = [
      %{
        id: EventProducer,
        start: {
          Vaporator.ClientFs.EventProducer,
          :start_link,
          [{:queue.new(), 0}]
        },
        type: :worker
      },
      %{
        id: EventConsumer,
        start: {
          Vaporator.ClientFs.EventConsumer,
          :start_link,
          []
        },
        type: :supervisor
      },
      {Vaporator.Cache, name: Vaporator.Cache},
      %{
        id: ClientFs.EventMonitor,
        start: {
          Vaporator.ClientFs.EventMonitor,
          :start_link,
          [Vaporator.ClientFs.sync_dirs]
        }
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vaporator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
