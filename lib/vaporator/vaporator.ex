defmodule Vaporator do
  @moduledoc """

  """
  use Application

  def start(_type, _args) do
    Vaporator.Supervisor.start_link()
  end
end

defmodule Vaporator.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      %{
        id: EventMonitor.Supervisor,
        start: {
          Vaporator.ClientFs.EventMonitor.Supervisor,
          :start_link,
          []
        },
        type: :supervisor
      },
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
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
