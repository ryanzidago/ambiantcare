defmodule Ambiantcare.MedicalNotes.MedicalNote do
  use Ecto.Schema

  alias __MODULE__
  alias Ambiantcare.MedicalNotes.Template
  alias Ambiantcare.Accounts.User
  alias Ambiantcare.Consultations.Consultation

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "medical_notes" do
    belongs_to :template, Template
    belongs_to :user, User
    belongs_to :consultation, Consultation

    field :fields, Ambiantcare.Encrypted.MapList

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = medical_note, attrs) do
    medical_note
    |> cast(attrs, [:fields, :user_id, :consultation_id, :template_id])
    |> validate_required([:fields, :user_id, :consultation_id, :template_id])
  end

  def from_template(%Template{} = template) do
    %__MODULE__{
      template_id: template.id,
      fields: Enum.map(template.fields, &MedicalNote.Field.from_template/1)
    }
  end
end
