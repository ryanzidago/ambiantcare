defmodule Ambiantcare.MedicalNotes do
  alias Ambiantcare.MedicalNotes.MedicalNote
  alias Ambiantcare.Accounts.User
  alias Ambiantcare.Consultations.Consultation

  alias Ambiantcare.Repo

  alias Ecto.Changeset

  import Ecto.Query

  @spec create_medical_note(map() | Changeset.t()) ::
          {:ok, MedicalNote.t()} | {:error, Changeset.t()}
  def create_medical_note(%Changeset{} = changeset) do
    Repo.insert(changeset)
  end

  def create_medical_note(%{} = attrs) do
    %MedicalNote{}
    |> MedicalNote.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_latest_medical_note(User.t(), Consultation.t()) :: MedicalNote.t() | nil
  def get_latest_medical_note(%User{} = user, %Consultation{} = consultation) do
    from(mn in MedicalNote, as: :mn)
    |> where([mn: mn], mn.user_id == ^user.id)
    |> where([mn: mn], mn.consultation_id == ^consultation.id)
    |> order_by([mn: mn], desc: mn.inserted_at)
    |> limit(1)
    |> Repo.one()
  end
end
