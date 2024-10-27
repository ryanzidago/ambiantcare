defmodule Ambiantcare.MedicalNotes.Prompts do
  @moduledoc """
  Module for generating prompts for medical notes.
  """

  alias Ambiantcare.MedicalNotes.Template

  @spec medical_note_user_prompt(map()) :: String.t()
  def medical_note_user_prompt(params) do
    context = Map.get(params, :context)
    transcription = Map.fetch!(params, :transcription)
    template = Map.fetch!(params, :template)

    """
    # Doctor Provided Context
    #{context}

    # Consultation Transcription
    #{transcription}

    # Medical Note Template
    #{Template.to_prompt(template)}
    """
  end

  @spec consultation_title_user_prompt(String.t()) :: String.t()
  def consultation_title_user_prompt(transcription) do
    """
    # Consultation Transcription
    #{transcription}
    """
  end
end
