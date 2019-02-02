defmodule Vaporator.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: :supervisor)
  end

  def init(_args) do
    children = [
      worker(Vaporator.Middleware, []),
      worker(Vaporator.ClientFs, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
