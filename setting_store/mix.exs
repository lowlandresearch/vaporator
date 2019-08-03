defmodule SettingStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :setting_store,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:persistent_storage],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {
        :persistent_storage,
        github: "cellulose/persistent_storage", tag: "v0.10.1"
      }
    ]
  end
end
