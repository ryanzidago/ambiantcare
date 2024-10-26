defmodule AmbiantcareWeb.ConsultationsLive.Helpers do
  use Gettext, backend: AmbiantcareWeb.Gettext

  alias Ecto.Changeset
  alias Phoenix.LiveView.AsyncResult

  alias Ambiantcare.MedicalNotes.MedicalNote

  # @spec to_text(MedicalNote.t() | Changeset.t(), DateTime.t()) :: String.t()
  def to_text(%MedicalNote{} = medical_note, datetime) do
    header = gettext("Medical Note") <> " " <> "#{datetime}\n\n"

    body =
      Enum.map_join(medical_note.fields, "\n\n", fn field ->
        Gettext.gettext(AmbiantcareWeb.Gettext, field.label) <> ":\n" <> (field.value || "")
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

  def use_local_stt? do
    Keyword.get(ai_config(), :use_local_stt, false)
  end

  defp ai_config() do
    Application.get_env(:ambiantcare, Ambiantcare.AI, [])
  end

  def static_dir, do: Path.join(priv_dir(), "static")
  def priv_dir, do: Application.app_dir(:ambiantcare, "priv")
end
