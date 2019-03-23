defmodule Vaporator.MixProject do
  use Mix.Project

  def project do
    [
      app: :vaporator,
      version: "0.0.1",
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
      extra_applications: [:logger, :gen_stage, :sentix],
      mod: {Vaporator, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5.0"},
      {:poison, "~> 4.0.1"},
      {:json, "~> 1.2.1"},
      {:timex, "~> 3.1"},
      {:dir_walker, "~> 0.0.8"},
      {:sentix, "~> 1.0"},
      {:gen_stage, "~> 0.11"},
      {:excoveralls, "~> 0.10", only: :test},
      {:exvcr, "~> 0.10", only: :test}
    ]
  end
end
