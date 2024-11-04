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

  describe "get_latest_medical_note/2" do
    test "when consultation is provided" do
      user = insert(:user)
      template = insert(:template, user: user)
      consultation = insert(:consultation, user: user)

      insert(:medical_note,
        user: user,
        template: template,
        consultation: consultation,
        inserted_at: ~U[2024-11-23 10:00:00Z]
      )

      latest_medical_note =
        insert(:medical_note,
          user: user,
          template: template,
          consultation: consultation,
          inserted_at: ~U[2024-11-25 10:00:00Z]
        )

      assert medical_note = MedicalNotes.get_latest_medical_note(user, consultation)
      assert medical_note.id == latest_medical_note.id
    end

    test "when consultation is `nil`" do
      user = insert(:user)

      refute MedicalNotes.get_latest_medical_note(user, nil)

      template = insert(:template, user: user)

      insert(:medical_note,
        user: user,
        template: template,
        inserted_at: ~U[2024-11-23 10:00:00Z]
      )

      insert(:medical_note,
        user: user,
        template: template,
        inserted_at: ~U[2024-11-25 10:00:00Z]
      )

      refute MedicalNotes.get_latest_medical_note(user, nil)
    end
  end
end
