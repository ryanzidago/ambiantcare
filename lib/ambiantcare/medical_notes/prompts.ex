defmodule Ambiantcare.MedicalNotes.Prompts do
  @moduledoc """
  Module for generating prompts for medical notes.
  """

  alias Ambiantcare.MedicalNotes.Template

  def compose(params) do
    context = Map.get(params, :context)
    transcription = Map.fetch!(params, :transcription)
    template = Map.fetch!(params, :template)

    instructions = """
    # Doctor Provided Context
    <%= @context %>

    # Consultation Transcription
    <%= @transcription %>

    # Medical Note Template
    <%= @schema %>
    """

    assigns = [
      context: context,
      transcription: transcription,
      schema: Template.to_prompt(template)
    ]

    EEx.eval_string(instructions, assigns: assigns)
  end
end
