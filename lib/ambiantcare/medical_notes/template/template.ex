defmodule Ambiantcare.MedicalNotes.Template do
  use Ecto.Schema

  alias __MODULE__

  import Ecto.Changeset

  schema "medical_notes" do
    field :key, :string
    field :title, :string
    field :description, :string

    belongs_to :template, __MODULE__

    embeds_many :fields, Template.Field
  end

  def changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = medical_note, attrs) do
    medical_note
    |> cast(attrs, [:title, :description, :key])
    |> cast_embed(:fields, with: &Template.Field.changeset/2)
    |> validate_required([:title, :description])
  end

  def default_template do
    default_template_attrs()
    |> changeset()
    |> apply_changes()
  end

  def default_template_attrs do
    %{
      key: "0",
      title: Gettext.gettext(AmbiantcareWeb.Gettext, "Default"),
      description: "This is the default template for medical notes",
      fields: [
        %{
          name: :chief_complaint,
          label: "Chief Complaint",
          description: "The main reason for the patient's visit",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 0
        },
        %{
          name: :history_of_present_illness,
          label: "History of Present Illness",
          description: "A detailed description of the patient's current illness",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 1
        },
        %{
          name: :assessment,
          label: "Assessment",
          description: "The patient's diagnosis",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 2
        },
        %{
          name: :plan,
          label: "Plan",
          description: "The patient's treatment plan",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 3
        },
        %{
          name: :medications,
          label: "Medications",
          description: "The patient's current medications",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :bullet,
          is_visible: true,
          position: 4
        },
        %{
          name: :physical_examination,
          label: "Physical Examination",
          description: "The patient's physical examination",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 5
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
      key: "1",
      title: Gettext.gettext(AmbiantcareWeb.Gettext, "Gastroenterology"),
      description: "This is the default template for gastroenterology notes",
      fields: [
        %{
          name: :chief_complaint,
          label: "Present Medical History",
          description: "The patient's current medical history",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 0
        },
        %{
          name: :past_medical_history,
          label: "Past Medical History",
          description: "The patient's past medical history",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 1
        },
        %{
          name: :home_medications,
          label: "Home Medications",
          description: "The patient's current medications",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :bullet,
          is_visible: true,
          position: 2
        },
        %{
          name: :allergies,
          label: "Allergies",
          description: "The patient's allergies",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :bullet,
          is_visible: true,
          position: 3
        },
        %{
          name: :physical_examination,
          label: "Physical Examination",
          description: "The patient's physical examination",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 4
        },
        %{
          name: :conclusions,
          label: "Conclusions",
          description: "The patient's diagnosis",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 5
        },
        %{
          name: :therapeutic_advices,
          label: "Therapeutic Advices",
          description: "The patient's treatment plan",
          autofill_instructions: "",
          autofill_enabled: true,
          writting_style: :prose,
          is_visible: true,
          position: 6
        }
      ]
    }
  end

  def to_prompt(%__MODULE__{} = template) do
    template.fields
    |> Map.new(fn field -> {field.name, "string"} end)
    |> Jason.encode!()
  end
end
