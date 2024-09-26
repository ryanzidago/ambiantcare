defmodule Clipboard.MedicalNotes.Template.Field do
  use Ecto.Schema

  alias Clipboard.MedicalNotes.FieldNames

  import Ecto.Changeset

  embedded_schema do
    field :name, Ecto.Enum, values: FieldNames.names()
    field :label, :string
    field :description, :string
    field :autofill_instructions, :string
    field :autofill_enabled, :boolean, default: false
    field :is_visible, :boolean, default: false
    field :position, :integer
    field :writting_style, Ecto.Enum, values: [:bullet, :prose], default: :prose
    field :input_type, Ecto.Enum, values: [:text, :textarea], default: :textarea
  end

  def changeset(attrs \\ %{}) when is_map(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = field, attrs) when is_map(attrs) do
    field
    |> cast(attrs, [
      :name,
      :label,
      :description,
      :autofill_instructions,
      :autofill_enabled,
      :writting_style,
      :is_visible,
      :input_type,
      :position
    ])
    |> validate_required([:name, :label])
  end
end
