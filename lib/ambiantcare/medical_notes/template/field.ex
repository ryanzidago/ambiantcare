defmodule Ambiantcare.MedicalNotes.Template.Field do
  use Ecto.Schema

  alias Ambiantcare.MedicalNotes.FieldNames

  import Ecto.Changeset

  embedded_schema do
    field :name, Ecto.Enum, values: FieldNames.names()
    field :label, :string
    field :description, :string
    field :position, :integer
    field :input_type, Ecto.Enum, values: [:text, :textarea], default: :textarea
  end

  def changeset(attrs \\ %{}) when is_map(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = field, attrs) when is_map(attrs) do
    field
    |> cast(attrs, [
      :name,
      :description,
      :label,
      :input_type,
      :position
    ])
    |> validate_required([:name, :label])
  end
end
