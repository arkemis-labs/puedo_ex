defmodule Mix.Tasks.PuedoEcto.Gen.Migration do
  use Mix.Task

  @shortdoc "Copies PuedoEcto migrations to your project"

  @moduledoc """
  Copies Ecto migrations from the puedo_ecto package into your project's priv directory.

  The destination folder is derived from the engine.

  ## Usage

      mix puedo_ecto.gen.migration --engine your_engine
      mix puedo_ecto.gen.migration -e your_engine
      mix puedo_ecto.gen.migration --list

  ## Options

    * `--engine`, `-e` - the Database engine (default to postgres)
    * `--list`, `-l`   - list all supported engines
  """

  @supported_engines ["postgres"]

  @impl true
  def run(args) do
    {opts, _} =
      OptionParser.parse!(args,
        strict: [engine: :string, list: :boolean],
        aliases: [e: :engine, l: :list]
      )

    if opts[:list] do
      Mix.shell().info("Supported engines:")
      Enum.each(@supported_engines, &Mix.shell().info("  * #{&1}"))
    else
      engine =
        opts[:engine] ||
          Mix.raise("No engine provided. Use: mix puedo_ecto.gen.migration --engine your_engine")

      folder =
        Enum.find(@supported_engines, &(&1 == engine)) || "postgres"

      Mix.Task.run("compile", [])

      source_dir = Application.app_dir(:puedo_ecto, Path.join(["priv", "migrations", folder]))

      dest_dir = Path.join([File.cwd!(), "priv", "migrations", "puedo_ecto"])

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

          mix ecto.migrate --repo MyApp.Repo
      """)
    end
  end
end
