defmodule Ambiantcare.Repo.Migrations.AddTemplates do
  use Ecto.Migration

  def change do
    create table(:medical_note_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :is_default, :boolean, default: false, null: false
      add :title, :string, null: false
      add :description, :string
      add :fields, {:array, :map}, null: false, default: []

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:medical_note_templates, [:user_id])

    create unique_index(:medical_note_templates, [:user_id, :is_default],
             where: "is_default = true"
           )

    create unique_index(:medical_note_templates, [:user_id, :title])
  end
end
