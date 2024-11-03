defmodule Mix.Tasks.Ecto.Gen.DataMigration do
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto
  import Mix.EctoSQL

  @shortdoc "Creates a data migration"

  @impl true
  def run(args) do
    repos = parse_repo(args)

    Enum.map(repos, fn repo ->
      case OptionParser.parse!(args, strict: []) do
        {_opts, [name]} ->
          ensure_repo(repo, args)
          path = Path.join(source_repo_priv(repo), "data_migrations")
          base_name = "#{underscore(name)}.exs"
          filename = "#{timestamp()}_#{base_name}"
          file = Path.join(path, filename)
          fuzzy_path = Path.join(path, "*_#{base_name}")

          if Enum.any?(Path.wildcard(fuzzy_path)) do
            Mix.raise(
              "data migration can't be created, there is already a migration file with name #{name}."
            )
          end

          assigns = [
            module: Module.concat([repo, DataMigrations, camelize(name)]),
            filename: filename
          ]

          create_file(file, migration_template(assigns))

          file

        {_, _} ->
          Mix.raise(
            "expected ecto.gen.data_migration to receive the migration file name, " <>
              "got: #{inspect(Enum.join(args, " "))}"
          )
      end
    end)
  end

  defp timestamp do
    Calendar.strftime(DateTime.utc_now(), "%Y_%m_%d__%H_%M_%S")
  end

  template = """
  defmodule <%= inspect(@module) %> do
    @moduledoc \"""
    This can be used from the console like so:

      ```
      [module] = c "\#{:code.priv_dir(:ambiantcare)}/repo/data_migrations/<%= @filename %>"
      module.execute()
      ```
    \"""

    alias Ambiantcare.Repo

    def execute do
    end
  end
  """

  embed_template(:migration, template)
end
