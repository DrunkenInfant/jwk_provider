defmodule JwkProvider.MixProject do
  use Mix.Project

  def project do
    [
      app: :jwk_provider,
      version: "0.2.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:vault_client, github: "PlugAndTrade/vault-client-elixir", tag: "0.3.0"},
      {:x509, github: "PlugAndTrade/elixir-x509", tag: "0.4.0"},
    ]
  end
end
