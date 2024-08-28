defmodule Clipboard.MedicalNotes.MedicalNote do
  use Ecto.Schema

  alias Ecto.Changeset
  import Ecto.Changeset

  @type t :: %__MODULE__{
          chief_complaint: binary(),
          history_of_present_illness: binary(),
          assessment: binary(),
          plan: binary(),
          medications: binary(),
          physical_examination: binary()
        }

  schema "medical_notes" do
    field :chief_complaint, :string
    field :history_of_present_illness, :string
    field :assessment, :string
    field :plan, :string
    field :medications, :string
    field :physical_examination, :string

    timestamps()
  end

  @spec changeset(map()) :: Changeset.t()
  def changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end

  @spec changeset(__MODULE__.t(), map()) :: Changeset.t()
  def changeset(%__MODULE__{}, attrs = %{}) do
    %__MODULE__{}
    |> cast(attrs, [
      :chief_complaint,
      :history_of_present_illness,
      :assessment,
      :plan,
      :medications,
      :physical_examination
    ])
  end
end
