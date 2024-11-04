defmodule Ambiantcare.Repo.Migrations.AddMedicalNotes do
  use Ecto.Migration

  def change do
    create table(:medical_notes) do
      add :fields, :binary, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :consultation_id, references(:consultations, on_delete: :delete_all), null: false
      add :template_id, references(:medical_note_templates, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:medical_notes, [:user_id])
    create index(:medical_notes, [:consultation_id])
    create index(:medical_notes, [:template_id])
  end
end
