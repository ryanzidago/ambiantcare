defmodule Ambiantcare.MedicalNotes.Prompts do
  @moduledoc """
  Module for generating prompts for medical notes.
  """

  alias Ambiantcare.MedicalNotes.Template

  def user(params) do
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
end
