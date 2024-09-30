defmodule Ambiantcare.MedicalNotes.Prompts do
  @moduledoc """
  Module for generating prompts for medical notes.
  """

  alias Ambiantcare.MedicalNotes.Template

  @spec transcription_to_medical_note(String.t(), Template.t()) :: String.t()
  def transcription_to_medical_note(transcription, %Template{} = template) do
    context =
      "You are a medical assistant that structures patient visit transcriptions into medical notes."

    instructions = """
    <%= @context %>

    Structure this patient visit transcription:
    <%= @transcription %>

    Into the following JSON object:
    <%= @schema %>

    Only reply with the JSON object.
    """

    assigns = [
      context: context,
      transcription: transcription,
      schema: Template.to_prompt(template)
    ]

    EEx.eval_string(instructions, assigns: assigns)
  end
end
