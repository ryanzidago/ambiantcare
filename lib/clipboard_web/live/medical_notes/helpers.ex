defmodule ClipboardWeb.MedicalNotesLive.Helpers do
  use Gettext, backend: ClipboardWeb.Gettext

  alias Ecto.Changeset
  alias Phoenix.LiveView.AsyncResult

  alias Clipboard.MedicalNotes.MedicalNote

  @spec to_text(MedicalNote.t() | Changeset.t(), DateTime.t()) :: String.t()
  def to_text(%MedicalNote{} = medical_note, datetime) do
    """
    #{gettext("Medical Note")} - #{datetime}

    #{gettext("Chief Complaint")}:
    #{medical_note.chief_complaint}

    #{gettext("History of Present Illness")}:
    #{medical_note.history_of_present_illness}

    #{gettext("Assessment")}:
    #{medical_note.assessment}

    #{gettext("Plan")}:
    #{medical_note.plan}

    #{gettext("Medications")}:
    #{medical_note.medications}

    #{gettext("Physical Examination")}:
    #{medical_note.physical_examination}
    """
  end

  def to_text(%Changeset{} = changeset, datetime) do
    changeset
    |> Changeset.apply_changes()
    |> to_text(datetime)
  end

  def to_text(%AsyncResult{ok?: true, result: %Changeset{}} = async_result, datetime) do
    to_text(async_result.result, datetime)
  end
end
