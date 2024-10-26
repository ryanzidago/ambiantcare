defmodule Ambiantcare.Repo.Migrations.AddConsultations do
  use Ecto.Migration

  def change do
    create table(:consultations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :label, :string, null: false
      add :transcription, :binary
      add :context, :binary
      add :start_datetime, :utc_datetime
      add :end_datetime, :utc_datetime

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:consultations, [:user_id])
  end
end
