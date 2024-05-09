defmodule Minikv.MixProject do
  use Mix.Project

  def project do
    [
      app: :minikv,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {Minikv, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:libcluster, "~> 3.3"},
      {:local_cluster, "~> 1.2", only: [:test]}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
