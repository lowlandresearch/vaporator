defmodule Firmware.MixProject do
  use Mix.Project

  @app :vaporator
  @version "0.1.0"
  @all_targets [:rpi3]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.6"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Firmware.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.5.0", runtime: false},
      {:nerves_hub_cli, "~> 0.9.0"},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.8.0"},
      {:toolshed, "~> 0.2.10"},
      {:dhcp_server, "~> 0.7.0"},

      # Intra-Project Dependencies
      {:setting_store, path: "../setting_store"},
      {:filesync, path: "../filesync"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.10.2"},
      {:nerves_hub, "~> 0.7.4"},
      {:nerves_time, "~> 0.2.1"},
      {:nerves_init_gadget, "~> 0.6.0", targets: @all_targets},

      # Dependencies for specific targets
      {:nerves_system_rpi3, "~> 1.8.1", runtime: false, targets: :rpi3},
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble]
    ]
  end
end
