defmodule Ambiantcare.MedicalNotes.Prompts do
  @moduledoc """
  Module for generating prompts for medical notes.
  """

  alias Ambiantcare.MedicalNotes.Template

  def compose(params) do
    context = Map.get(params, :context)
    transcription = Map.fetch!(params, :transcription)
    template = Map.fetch!(params, :template)

    require IEx
    IEx.pry()

    role =
      "You are a medical assistant that structures patient visit transcriptions into medical notes."

    instructions = """
    <%= @role %>

    The doctor has provided the following additional context about the patient:
    <%= if is_binary(@context) do %>
      <%= @context %>
    <% end %>

    Structure this patient visit transcription:
    <%= @transcription %>

    Into the following JSON object:
    <%= @schema %>

    Only reply with the JSON object.
    """

    assigns = [
      role: role,
      context: context,
      transcription: transcription,
      schema: Template.to_prompt(template)
    ]

    EEx.eval_string(instructions, assigns: assigns)
  end
end
