defmodule Vaporator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    if target_is_not_host?() do
      maybe_start_wizard()
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vaporator.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: Vaporator.Worker.start_link(arg)
        # {Vaporator.Worker, arg},
        Vaporator.Repo
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Vaporator.Worker.start_link(arg)
      # {Vaporator.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Vaporator.Worker.start_link(arg)
      # {Vaporator.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:vaporator, :target)
  end

  defp maybe_start_wizard() do
    if should_start_wizard?() do
      VintageNetWizard.run_wizard()
    end
  end

  defp should_start_wizard?() do
    wifi_configured?()
  end

  defp target_is_not_host?() do
    target() != :host
  end

  defp wifi_configured?() do
    VintageNet.get(["interface", "wlan0", "state"]) == :configured
  end
end
