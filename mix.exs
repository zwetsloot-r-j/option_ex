defmodule OptionEx.MixProject do
  use Mix.Project

  @github "https://github.com/nanaki04/option_ex"

  def project do
    [
      app: :option_ex,
      version: "0.1.0",
      description: "Module to make working with potential nil values safer and more convenient by using {:some, value} or :none instead",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "OptionEx",
      source_url: @github,
      docs: [
        main: "OptionEx",
        extras: ["README.md"]
      ],

      # Hex Package
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.16", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      lincenses: ["MIT"],
      maintainers: ["Robert Jan Zwetsloot"],
      links: %{github: @github}
    ]
  end
end
