defmodule Ambiantcare.Repo.Migrations.AddWaitlistUserEntries do
  use Ecto.Migration

  def change do
    create table(:waitlist_user_entries) do
      add :email, :string, null: false
      add :first_name, :string
      add :last_name, :string
      add :specialty, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:waitlist_user_entries, [:email])
  end
end
