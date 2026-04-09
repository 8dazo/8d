defmodule EightDCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :eight_d_core,
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
      extra_applications: [:logger, :mnesia, :crypto],
      mod: {EightDCore.Application, []}
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.34.0"}
    ]
  end
end
