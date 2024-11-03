defmodule Ambiantcare.MedicalNotes.TemplatesTest do
  use Ambiantcare.DataCase, async: true

  alias Ambiantcare.MedicalNotes.Templates
  alias Ambiantcare.MedicalNotes.Template

  import Ecto.Query

  describe "templates_query/1" do
    test "returns a user templates" do
      user = insert(:user)

      insert(:template,
        user: user,
        title: "General Medicine",
        is_default: true,
        inserted_at: ~U[2024-10-27 10:00:00Z]
      )

      insert(:template,
        user: user,
        title: "Cardiology",
        is_default: false,
        inserted_at: ~U[2024-09-01 10:00:00Z]
      )

      insert(:template,
        user: user,
        title: "Dermatology",
        is_default: false,
        inserted_at: ~U[2024-10-25 10:00:00Z]
      )

      assert templates =
               user
               |> Templates.templates_query()
               |> Repo.all()

      assert ["General Medicine", "Cardiology", "Dermatology"] = Enum.map(templates, & &1.title)
    end
  end

  describe "change_user_default_template" do
    test "returns a changeset with the new default value" do
      user = insert(:user)
      template = insert(:template, user: user, title: "General Medicine", is_default: false)

      assert changeset =
               Templates.change_user_default_template(user, template, %{is_default: true})

      assert %{is_default: true} = changeset.changes
    end
  end

  describe "update_user_default_template/3" do
    test "updates the default template" do
      user = insert(:user)

      previous_default_template =
        insert(:template, user: user, title: "General Medicine", is_default: true)

      template_to_mark_as_default =
        insert(:template, user: user, title: "Cardiology", is_default: false)

      {:ok, _} =
        Templates.update_user_default_template(
          user,
          previous_default_template,
          template_to_mark_as_default
        )

      assert template_to_mark_as_default.id ==
               Repo.one!(from(t in Template, where: t.is_default, select: t.id))
    end
  end
end
