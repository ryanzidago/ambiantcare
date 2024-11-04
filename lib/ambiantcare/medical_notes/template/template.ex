defmodule Ambiantcare.MedicalNotes.Template do
  use Ecto.Schema
  use Gettext, backend: AmbiantcareWeb.Gettext

  alias Ambiantcare.Accounts.User

  import Ecto.Changeset

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "medical_note_templates" do
    field :is_default, :boolean, default: false
    field :title, :string
    field :description, :string

    field :fields, {:array, :map}

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = medical_note, attrs) do
    medical_note
    |> cast(attrs, [:fields, :title, :description, :is_default, :user_id])
    |> validate_required([:fields, :title, :is_default, :user_id])
  end

  def default_templates_attrs(attrs \\ %{}) do
    Enum.map(
      [
        default_template_attrs(),
        gastroenterology_template_attrs()
      ],
      &Map.merge(&1, attrs)
    )
  end

  def default_template do
    default_template_attrs()
    |> changeset()
    |> apply_changes()
  end

  def default_template_attrs do
    %{
      title: gettext("General Medicine"),
      description: "This is the default template for medical notes",
      is_default: true,
      fields: [
        %{
          "name" => "chief_complaint",
          "label" => gettext("Chief Complaint"),
          "description" => "The main reason for the patient's visit",
          "position" => 0
        },
        %{
          "name" => "present_medical_history",
          "label" => gettext("Present medical history"),
          "description" => "A detailed description of the patient's current illness",
          "position" => 1
        },
        %{
          "name" => "past_medical_history",
          "label" => gettext("Past medical history"),
          "description" => "The patient's past medical history",
          "position" => 2
        },
        %{
          "name" => "ongoing_therapy",
          "label" => gettext("Ongoing therapy"),
          "description" => "Ongoing therapy",
          "position" => 3
        },
        %{
          "name" => "physical_assessment",
          "label" => gettext("Physical Assessment"),
          "description" => "The patient's physical assessment",
          "position" => 4
        },
        %{
          "name" => "therapeutic_plan",
          "label" => gettext("Therapeutic Plan"),
          "description" => "The patient's therapeutic plan",
          "position" => 5
        }
      ]
    }
  end

  def gastroenterology_template do
    gastroenterology_template_attrs()
    |> changeset()
    |> apply_changes()
  end

  def gastroenterology_template_attrs do
    %{
      title: gettext("Gastroenterology"),
      description: "This is the default template for gastroenterology notes",
      is_default: false,
      fields: [
        %{
          "name" => "chief_complaint",
          "label" => gettext("Present Medical History"),
          "description" => "The patient's current medical history",
          "position" => 0
        },
        %{
          "name" => "past_medical_history",
          "label" => gettext("Past Medical History"),
          "description" => "The patient's past medical history",
          "position" => 1
        },
        %{
          "name" => "home_medications",
          "label" => gettext("Home Medications"),
          "description" => "The patient's current medications",
          "position" => 2
        },
        %{
          "name" => "allergies",
          "label" => gettext("Allergies"),
          "description" => "The patient's allergies",
          "position" => 3
        },
        %{
          "name" => "physical_examination",
          "label" => gettext("Physical Examination"),
          "description" => "The patient's physical examination",
          "position" => 4
        },
        %{
          "name" => "conclusions",
          "label" => gettext("Conclusions"),
          "description" => "The patient's diagnosis",
          "position" => 5
        },
        %{
          "name" => "therapeutic_advices",
          "label" => gettext("Therapeutic Advices"),
          "description" => "The patient's treatment plan",
          "position" => 6
        }
      ]
    }
  end

  def to_prompt(%__MODULE__{} = template) do
    template.fields
    |> Map.new(fn field -> {field["name"], "string"} end)
    |> Jason.encode!()
  end
end
