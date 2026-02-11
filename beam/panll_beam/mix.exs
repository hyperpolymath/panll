defmodule PanllBeam.MixProject do
  use Mix.Project

  def project do
    [
      app: :panll_beam,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PanllBeam.Application, []}
    ]
  end

  defp deps do
    [
      {:absinthe, "~> 1.7"},
      {:absinthe_plug, "~> 1.5"},
      {:bandit, "~> 1.5"},
      {:grpc, "~> 0.8"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.15"},
      {:protobuf, "~> 0.12"}
    ]
  end
end
