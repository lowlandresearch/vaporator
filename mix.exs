defmodule Vaporator.MixProject do
  use Mix.Project

  @app :vaporator
  @version "0.1.0"
  @all_targets [:rpi3, :rpi4]

  def project do
    [
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        plt_file: {:no_warn, "vaporator.plt"}
      ],
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.10"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Vaporator.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.13.3", only: :test},
      {:credo, "~> 1.5.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
      # Dependencies for all targets
      {:nerves, "~> 1.7.0", runtime: false},
      {:nerves_hub_cli, "~> 0.10", runtime: false},
      {:shoehorn, "~> 0.7.0"},
      {:ring_logger, "~> 0.8.1"},
      {:toolshed, "~> 0.2.14"},
      {:sqlite_ecto2, "~> 2.4"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.11.3", targets: @all_targets},
      {:nerves_pack, "~> 0.4.1", targets: @all_targets},
      {:nerves_hub_link, "~> 0.9.2", targets: @all_targets},
      {:nerves_time, "~> 0.4.2", targets: @all_targets},
      {:nerves_ssh, "~> 0.2.1", targets: @all_targets},
      {:vintage_net_wizard, "~> 0.4", targets: @all_targets},

      # Dependencies for specific targets
      {:nerves_system_rpi3, "~> 1.13", runtime: false, targets: :rpi3},
      {:nerves_system_rpi4, "~> 1.13", runtime: false, targets: :rpi4}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
