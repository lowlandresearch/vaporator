defmodule Vaporator do
  use Application

  def start(_type, _args) do
    Vaporator.Middleware.Supervisor.start_link
    Vaporator.ClientFs.Supervisor.start_link
  end
end