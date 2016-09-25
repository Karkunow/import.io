defmodule Importio.Mixfile do
  use Mix.Project

  def project do
    [app: :importio,
     version: "0.1.0",
     elixir: "~> 1.3",
     escript: [main_module: Importio],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :defmemo]]
  end

  defp deps do
    [
      {:poison, "~> 2.2"},
      {:defmemo, "~> 0.1.0"},
      {:control, "~> 0.0.4"}
    ]
  end
end
