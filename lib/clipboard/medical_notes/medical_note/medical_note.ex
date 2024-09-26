defmodule Clipboard.MedicalNotes.MedicalNote do
  use Ecto.Schema

  alias __MODULE__
  alias Clipboard.MedicalNotes.Template

  import Ecto.Changeset

  schema "medical_notes" do
    # belongs_to :author, Author
    # belongs_to :encounter, Encounter
    # belongs_to :organisation, Organisation

    field :title, :string

    belongs_to :template, Template

    embeds_many :fields, MedicalNote.Field
  end

  def changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = medical_note, attrs) do
    medical_note
    |> cast(attrs, [:title])
    |> cast_embed(:fields, with: &MedicalNote.Field.changeset/2)
    |> validate_required([:title])
  end

  def from_template(%Template{} = template) do
    %__MODULE__{
      title: "Untitled",
      template_id: template.id,
      fields: Enum.map(template.fields, &MedicalNote.Field.from_template/1)
    }
  end
end
