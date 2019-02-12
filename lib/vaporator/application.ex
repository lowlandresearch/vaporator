defmodule Vaporator do
  @moduledoc """
  Entry point for application

  https://hexdocs.pm/elixir/Application.html
  """
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("#{__MODULE__} starting")
    Vaporator.Supervisor.start_link()
  end
end

defmodule Vaporator.Supervisor do
  @moduledoc """
  Starts and supervises all of the application processes.

  Child Processes:
    - ClientFs.EventMonitor.Supervisor
    - ClientFs.EventProducer
    - ClientFs.EventConsumer
  """
  use Supervisor
  require Logger

  def start_link do
    Logger.info("#{__MODULE__} starting")
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Initalizes the supervisor and starts ClientFs.EventProducer,
  ClientFs.EventConsumer, ClientFs.EventMonitor.Supervisor.

  elixirschool.com/en/lessons/advanced/otp-supervisors/#child-specification

  Child order matters when initalizing.  EventMonitor sends events to
  EventProducer and then processed by EventConsumer.

  If EventProducer is not running when events begin flowing from EventMonitor,
  those events will be lost since we are using GenStage.cast/2 for async
  queueing.
  """
  def init(:ok) do
    Logger.info("#{__MODULE__} initializing")
    children = [
      %{
        id: EventProducer,
        start: {
          Vaporator.ClientFs.EventProducer,
          :start_link,
          []
        },
        type: :worker
      },
      %{
        id: EventConsumer,
        start: {
          Vaporator.ClientFs.EventConsumer,
          :start_link,
          [:ok]
        },
        type: :supervisor
      },
      %{
        id: EventMonitor.Supervisor,
        start: {
          Vaporator.ClientFs.EventMonitor.Supervisor,
          :start_link,
          []
        },
        type: :supervisor
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
