defmodule Vaporator do
  use Application

  def start(_type, _args) do
    Vaporator.Supervisor.start_link
  end
end