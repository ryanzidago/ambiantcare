defmodule Ambiantcare.ConsultationsTest do
  use Ambiantcare.DataCase

  alias Ambiantcare.Consultations
  alias Ambiantcare.Consultations.Consultation

  alias Ecto.Changeset

  describe "create_or_update_consultation/3" do
    test "creates a new consultation" do
      doctor = insert(:user)

      assert {:ok, consultation} =
               Consultations.create_or_update_consultation(
                 doctor,
                 %Consultation{},
                 %{
                   user_id: doctor.id,
                   title: "A Consultation",
                   transcription: "Hello doctor, I am sick!",
                   context: "The patient is a middle-aged male.",
                   start_datetime: ~U[2024-10-27 10:00:00Z],
                   end_datetime: ~U[2024-10-27 10:30:00Z]
                 }
               )

      assert %Consultation{} = consultation
      assert consultation.user_id == doctor.id
      assert consultation.title == "A Consultation"
      assert consultation.transcription == "Hello doctor, I am sick!"
      assert consultation.context == "The patient is a middle-aged male."
      assert consultation.start_datetime == ~U[2024-10-27 10:00:00Z]
      assert consultation.end_datetime == ~U[2024-10-27 10:30:00Z]
    end

    test "returns an error when the consultation is invalid" do
      doctor = insert(:user)

      assert {:error, changeset} =
               Consultations.create_or_update_consultation(
                 doctor,
                 %Consultation{},
                 %{
                   title: "A Consultation",
                   transcription: "Hello doctor, I am sick!",
                   context: "The patient is a middle-aged male.",
                   start_datetime: ~U[2024-10-27 10:00:00Z],
                   end_datetime: ~U[2024-10-27 10:30:00Z]
                 }
               )

      assert %Changeset{} = changeset
      assert changeset.errors[:user_id] == {"can't be blank", [validation: :required]}
    end

    test "updates an existing consultation" do
      doctor = insert(:user)
      previous_consultation = insert(:consultation, title: "Patient with fever.", user: doctor)

      assert {:ok, consultation} =
               Consultations.create_or_update_consultation(
                 doctor,
                 previous_consultation,
                 %{
                   title: "Patient with fever and cough."
                 }
               )

      assert %Consultation{} = consultation
      assert consultation.title == "Patient with fever and cough."
      assert consultation.transcription == previous_consultation.transcription
      assert consultation.context == previous_consultation.context
      assert consultation.start_datetime == previous_consultation.start_datetime
      assert consultation.end_datetime == previous_consultation.end_datetime
      assert consultation.user_id == previous_consultation.user_id
    end
  end
end
