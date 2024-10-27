defmodule Ambiantcare.Consultations.Consultation do
  @moduledoc """
  The Consultation context.
  """
  use Ecto.Schema
  use Gettext, backend: AmbiantcareWeb.Gettext

  alias Ambiantcare.Accounts.User
  alias Ambiantcare.Encrypted

  import Ecto.Changeset

  @default_title gettext("My consultation")

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "consultations" do
    field :title, :string
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
    |> validate_required([:user_id])
  end

  def default, do: %__MODULE__{}

  def default_title, do: @default_title
end
