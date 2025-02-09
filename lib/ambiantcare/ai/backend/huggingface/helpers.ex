defmodule Ambiantcare.AI.HuggingFace.Helpers do
  alias Ambiantcare.AI.HuggingFace
  alias Ambiantcare.AI.Inputs.SpeechToText

  @audio_models ~w(openai/whisper-large-v3 openai/whisper-large-v3-turbo)
  @text_models ~w(meta-llama/Meta-Llama-3.1-8B-Instruct)

  def audio_models, do: @audio_models
  def text_models, do: @text_models

  def validate_extension(filename) do
    extension = Path.extname(filename)

    if extension in expected_extensions() do
      :ok
    else
      {:error,
       invalid_extension:
         "Invalid file extension, expected one of #{inspect(expected_extensions())}, got: #{extension}"}
    end
  end

  defp expected_extensions, do: ~w(.mp3 .flac .wav .opus .ogg)

  def build_body(prompt, model, options) do
    system_prompt = Keyword.get(options, :system_prompt)
    stream = Keyword.get(options, :stream, false)
    format = Keyword.get(options, :format, "json")

    body =
      %{}
      |> Map.put("prompt", prompt)
      |> Map.put("model", model)
      |> Map.put("system_prompt", system_prompt)
      |> Map.put("stream", stream)
      |> Map.put("format", format)

    Jason.encode(body)
  end

  def config do
    Application.get_env(:ambiantcare, HuggingFace)
  end

  def content_type(%SpeechToText{} = input) do
    case input.upload_metadata do
      %{upload_type: :from_user_file_system} ->
        input.upload_metadata.client_filename
        |> Path.extname()
        |> String.replace(".", "")
        |> MIME.type()

      _ ->
        "audio/flac"
    end
  end

  def headers(opts) do
    content_type = Keyword.get(opts, :content_type)

    [
      {"Authorization", "Bearer #{config()[:api_key]}"},
      {"Accept", "application/json"}
    ] ++ if content_type, do: [{"Content-Type", content_type}], else: []
  end
end
