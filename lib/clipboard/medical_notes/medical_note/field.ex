defmodule Clipboard.MedicalNotes.MedicalNote.Field do
  use Ecto.Schema

  alias Clipboard.MedicalNotes.Template
  alias Clipboard.MedicalNotes.FieldNames

  import Ecto.Changeset

  embedded_schema do
    field :name, Ecto.Enum, values: FieldNames.names()
    field :label, :string
    field :value, :string
  end

  def changeset(attrs \\ %{}) when is_map(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = field, attrs) when is_map(attrs) do
    field
    |> cast(attrs, [
      :name,
      :label,
      :value
    ])
    |> validate_required([:name, :label])
  end

  def from_template(%Template.Field{} = field) do
    %__MODULE__{
      name: field.name,
      label: field.label
    }
  end
end
