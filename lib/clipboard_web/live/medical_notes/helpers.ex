defmodule ClipboardWeb.MedicalNotesLive.Helpers do
  use Gettext, backend: ClipboardWeb.Gettext

  alias Ecto.Changeset
  alias Phoenix.LiveView.AsyncResult

  alias Clipboard.MedicalNotes.MedicalNote

  # @spec to_text(MedicalNote.t() | Changeset.t(), DateTime.t()) :: String.t()
  def to_text(%MedicalNote{} = medical_note, datetime) do
    header = gettext("Medical Note") <> " " <> "#{datetime}\n\n"

    body =
      Enum.map_join(medical_note.fields, "\n\n", fn field ->
        Gettext.gettext(ClipboardWeb.Gettext, field.label) <> ":\n" <> (field.value || "")
      end)

    header <> body
  end

  def to_text(%Changeset{} = changeset, datetime) do
    changeset
    |> Changeset.apply_changes()
    |> to_text(datetime)
  end

  def to_text(%AsyncResult{ok?: true, result: %Changeset{}} = async_result, datetime) do
    to_text(async_result.result, datetime)
  end

  def to_fields(%{} = response) do
    Enum.map(response, fn {key, value} ->
      %{name: String.to_existing_atom(key), value: value}
    end)
  end
end
