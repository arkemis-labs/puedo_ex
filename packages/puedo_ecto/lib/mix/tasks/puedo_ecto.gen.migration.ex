defmodule Mix.Tasks.PuedoEcto.Gen.Migration do
  use Mix.Task

  @shortdoc "Copies PuedoEcto migrations to your project"

  @moduledoc """
  Copies Ecto migrations from the puedo_ecto package into your project's priv directory.

  The destination folder is derived from the repo's adapter.

  ## Usage

      mix puedo_ecto.gen.migration --repo MyApp.Repo
      mix puedo_ecto.gen.migration -r MyApp.Repo

  ## Options

    * `--repo`, `-r` - the Ecto repo module (required)
  """

  @supported_adapters %{
    Ecto.Adapters.Postgres => "postgres"
  }

  @impl true
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [repo: :string], aliases: [r: :repo])

    repo_name =
      opts[:repo] ||
        Mix.raise("No repo provided. Use: mix puedo_ecto.gen.migration --repo MyApp.Repo")

    Mix.Task.run("compile", [])

    repo = Module.concat([repo_name])

    adapter = repo.__adapter__()

    folder =
      Map.get(@supported_adapters, adapter) ||
        Mix.raise(
          "Unsupported adapter: #{inspect(adapter)}. " <>
            "Supported adapters: #{@supported_adapters |> Map.keys() |> Enum.map_join(", ", &inspect/1)}"
        )

    source_dir = Application.app_dir(:puedo_ecto, Path.join(["priv", "migrations", folder]
))


    dest_dir =
      Path.join([File.cwd!(), "priv", "migrations", "puedo_ecto"])

    File.mkdir_p!(dest_dir)

    source_dir
    |> File.ls!()
    |> Enum.each(fn file ->
      src = Path.join(source_dir, file)
      dst = Path.join(dest_dir, file)
      File.cp!(src, dst)
      Mix.shell().info([:green, "* creating ", :reset, Path.relative_to_cwd(dst)])
    end)

    Mix.shell().info("""

    Migrations copied to #{Path.relative_to_cwd(dest_dir)}.

    Run the following to apply them:

        mix ecto.migrate --repo #{repo_name}
    """)
  end
end
