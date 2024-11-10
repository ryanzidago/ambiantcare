defmodule Ambiantcare.AI.NumEx do
  alias Ambiantcare.AI
  alias Ambiantcare.AI.Inputs.SpeechToText

  @behaviour AI.Backend

  @impl AI.Backend
  @spec generate(SpeechToText.t()) :: {:ok, String.t()} | {:error, String.t()}
  def generate(%SpeechToText{} = input) do
    binary_input = build_binary(input)

    output = Nx.Serving.batched_run(Ambiantcare.Serving, binary_input)

    transcription =
      output.chunks
      |> Enum.map_join(& &1.text)
      |> String.trim()

    {:ok, transcription}
  end

  defp build_binary(%SpeechToText{} = input) do
    case input do
      %SpeechToText{upload_metadata: %{upload_type: :from_user_file_system}} ->
        filename = System.tmp_dir!() <> "_" <> Ecto.UUID.autogenerate()
        :ok = File.write!(filename, input.upload_metadata.binary)
        {:file, filename}

      %SpeechToText{upload_metadata: %{upload_type: :from_user_microphone}} ->
        Nx.from_binary(input.upload_metadata.binary, :f32)
    end
  end
end
