defmodule Puedo.MixProject do
  use Mix.Project

  def project do
    [
      app: :puedo,
      version: "0.1.0",
      elixir: "~> 1.18",
      description: "A flexible RBAC (Role-Based Access Control) engine for Elixir",
      start_permanent: Mix.env() == :prod,
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

  defp versioning do
    [
      tag_prefix: "puedo@v",
      commit_msg: "puedo@v%s",
      annotation: "tag release-%s",
      annotate: true
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
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

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
