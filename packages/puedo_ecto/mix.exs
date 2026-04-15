defmodule PuedoEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :puedo_ecto,
      version: "0.0.1",
      elixir: "~> 1.18",
      description: "Ecto persistence backend for Puedo RBAC engine",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      source_url: "https://github.com/arkemis-labs/puedo_ex",
      homepage_url: "https://github.com/arkemis-labs/puedo_ex",
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

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/arkemis-labs/puedo_ex"
      }
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
