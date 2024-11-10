defmodule Ambiantcare.Repo.DataMigrations.FixTemplatesLabels do
  @moduledoc """
  This can be used from the console like so:

    ```
    [module] = c "#{:code.priv_dir(:ambiantcare)}/repo/data_migrations/2024_11_09__18_36_43_fix_templates_labels.exs"
    module.execute()
    ```
  """

  alias Ambiantcare.MedicalNotes.Template

  alias Ambiantcare.Repo

  def execute do
    Repo.transaction(fn ->
      Template
      |> Repo.all()
      |> Enum.map(&fix_template/1)
    end)
  end

  defp fix_template(template) do
    fields = Enum.map(template.fields, &fix_field/1)

    template
    |> Template.changeset(%{fields: fields})
    |> Repo.update!()
  end

  defp fix_field(field) do
    Map.update!(field, "label", fn label ->
      label
      |> String.split(" ")
      |> Enum.map_join(" ", &String.capitalize/1)
    end)
  end
end
