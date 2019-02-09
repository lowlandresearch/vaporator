defmodule Vaporator.ClientFs.EventConsumer do
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
          max_demand: 5,
          min_demand: 3
        }
      ]
    ]
    
    ConsumerSupervisor.init(children, opts)
  end

end