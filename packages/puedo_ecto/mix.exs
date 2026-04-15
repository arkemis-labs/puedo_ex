defmodule PuedoEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :puedo_ecto,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      workspace: [
        tags: [{:scope, :package}]
      ],
      versioning: versioning()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp versioning do
    [
      tag_prefix: "puedo_ecto@v",
      commit_msg: "puedo_ecto@v%s",
      annotation: "tag release-%s",
      annotate: true
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:puedo, path: "../puedo"},
      {:ecto, "~> 3.13.0"},
      {:ecto_sql, "~> 3.13"},

      # Optional
      {:postgrex, "~> 0.22.0", optional: true}
    ]
  end
end
