defmodule Ambiantcare.Consultations.Consultation do
  @moduledoc """
  The Consultation context.
  """
  use Ecto.Schema
  use Gettext, backend: AmbiantcareWeb.Gettext

  alias Ambiantcare.Accounts.User
  alias Ambiantcare.Encrypted

  import Ecto.Changeset

  @default_label "My consultation"

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "consultations" do
    field :label, :string
    field :transcription, Encrypted.Binary
    field :context, Encrypted.Binary
    field :start_datetime, :utc_datetime
    field :end_datetime, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end

  @spec changeset(__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = consultation, attrs) do
    consultation
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> maybe_put_default_label()
    |> validate_required([:label, :user_id])
  end

  defp maybe_put_default_label(changeset) do
    if get_field(changeset, :label) do
      changeset
    else
      label = gettext(@default_label)
      put_change(changeset, :label, label)
    end
  end

  def default do
    %__MODULE__{label: gettext(@default_label)}
  end
end
