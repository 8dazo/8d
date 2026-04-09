defmodule EightDCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :eight_d_cli,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EightDCli.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eight_d_core, in_umbrella: true},
      {:eight_d_cognitive, in_umbrella: true},
      {:eight_d_swarm, in_umbrella: true}
    ]
  end
end
