defmodule Minikv.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/yassinrais/minikv"

  def project do
    [
      app: :minikv,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      aliases: aliases(),
      package: package(),
      docs: docs()
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
      {:local_cluster, "~> 1.2", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18.1", only: [:test]}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

  defp package do
    [
      description: """
        Minikv: A lightweight Elixir library for building distributed key-value stores (:ets),
         featuring asynchronous replication between nodes.
      """,
      maintainers: ["Yassine Rais"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      formatters: ["html"]
    ]
  end
end
