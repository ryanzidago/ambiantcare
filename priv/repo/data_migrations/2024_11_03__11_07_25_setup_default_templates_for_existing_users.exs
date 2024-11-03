defmodule Ambiantcare.Repo.DataMigrations.SetupDefaultTemplatesForExistingUsers do
  @moduledoc """
  This can be used from the console like so:

    ```
    [module] = c "#{:code.priv_dir(:ambiantcare)}/repo/data_migrations/2024_11_03__11_07_25_setup_default_templates_for_existing_users.exs"
    module.execute()
    ```
  """

 alias Ambiantcare.Repo
  alias Ambiantcare.Accounts.User
  alias Ambiantcare.MedicalNotes.Template

  import Ecto.Query

  def execute do
    users = users_without_any_templates()

    default_templates = [
      Map.put(Template.default_template_attrs(), :is_default, true),
      Template.gastroenterology_template_attrs(),
    ]

    Repo.transaction(fn ->
      Enum.each(users, fn user ->
        Enum.each(default_templates, fn attrs ->
          attrs
          |> Map.put(:user_id, user.id)
          |> Template.changeset()
          |> Repo.insert!()
        end)
      end)
    end)
  end

  defp users_without_any_templates do
    from(u in User, as: :u)
    |> join(:left, [u: u], t in assoc(u, :medical_note_templates), as: :t)
    |> where([t: t], is_nil(t.id))
    |> distinct(true)
    |> Repo.all()
  end
end
