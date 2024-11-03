defmodule Ambiantcare.MedicalNotesTest do
  use Ambiantcare.DataCase

  alias Ambiantcare.MedicalNotes
  alias Ambiantcare.MedicalNotes.MedicalNote

  describe "create_medical_note/1" do
    test "creates a medical note" do
      user = insert(:user)
      template = insert(:template, user: user)
      consultation = insert(:consultation, user: user)

      attrs = %{
        user_id: user.id,
        consultation_id: consultation.id,
        template_id: template.id,
        fields: [
          %{name: :chief_complaint, label: "Chief Complaint", value: "Headache"}
        ]
      }

      assert {:ok, medical_note} = MedicalNotes.create_medical_note(attrs)
      assert %MedicalNote{} = medical_note
      assert medical_note.user_id == user.id
      assert medical_note.consultation_id == consultation.id
      assert medical_note.template_id == template.id
    end
  end
end
