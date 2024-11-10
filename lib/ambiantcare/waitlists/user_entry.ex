defmodule Ambiantcare.Waitlists.UserEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          email: String.t(),
          phone_number: String.t(),
          specialty: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          inserted_at: UtcDateTime.t(),
          updated_at: UtcDateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "waitlist_user_entries" do
    field :email, :string
    field :phone_number, :string
    field :first_name, :string
    field :last_name, :string
    field :specialty, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:email, :first_name, :last_name, :specialty, :phone_number])
    |> validate_required([:email, :first_name, :last_name])
    |> validate_format(:email, ~r/@/)
  end
end
