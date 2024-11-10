defmodule Ambiantcare.AI.Inputs.SpeechToText do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_speech_to_text_inputs" do
    field :backend, Ecto.Enum, values: [:huggingface]
    field :model, :string
    field :filename, :string
    field :binary, :string
    field :upload_metadata, :map
  end
end
