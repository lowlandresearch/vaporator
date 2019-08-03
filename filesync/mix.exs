defmodule Filesync.MixProject do
  use Mix.Project

  def project do
    [
      app: :filesync,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      perferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :gen_stage]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5.0"},
      {:poison, "~> 4.0.1"},
      {:json, "~> 1.3.0"},
      {:timex, "~> 3.6"},
      {:ets, "~> 0.7"},
      {:dir_walker, "~> 0.0.8"},
      {:gen_stage, "~> 0.14"},
      {:excoveralls, "~> 0.11", only: :test},
      {:exvcr, "~> 0.10", only: :test},

      # Intra-Project Dependencies
      {:setting_store, path: "../setting_store"}
    ]
  end
end
