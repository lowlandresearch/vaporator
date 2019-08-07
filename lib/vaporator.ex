defmodule Vaporator do
  @moduledoc """
  
  """

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options

    opts = [strategy: :one_for_one, name: Vaporator.Supervisor]

    children = [
      Vaporator.Cache,
      Vaporator.Client.EventProducer,
      Vaporator.Client.EventConsumer,
      Vaporator.Client.EventMonitor,
      {Task, fn -> Vaporator.Settings.init() end}
    ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Testme.Worker.start_link(arg)
      # {Testme.Worker, arg},
    ]
  end

  def children(_target) do

    dhcp_options = [
      gateway: "10.0.0.1",
      netmask: "255.255.255.0",
      range: {"10.0.0.1", "10.0.0.10"},
      domain_servers: ["10.0.0.1"]
    ]

    [
      {DHCPServer, ["eth0", dhcp_options]},
      NervesHub.Supervisor,
      Vaporator.Monitor
    ]
  end

  def target do
    Application.get_env(:vaporator, :target)
  end
end
