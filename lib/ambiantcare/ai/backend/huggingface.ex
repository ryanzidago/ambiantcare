defmodule Ambiantcare.AI.HuggingFace do
  alias Ambiantcare.AI
  alias Ambiantcare.AI.Inputs.SpeechToText

  import Ambiantcare.AI.HuggingFace.Helpers

  @dedicated_models_mapper %{
    "openai/whisper-large-v3" => :open_ai_whisper_large_v3,
    "openai/whisper-large-v3-turbo" => :open_ai_whisper_large_v3_turbo,
    "meta-llama/Meta-Llama-3.1-8B-Instruct" => :meta_llama_3_1_8B_instruct
  }

  @behaviour AI.Backend

  @impl AI.Backend
  def generate(%SpeechToText{} = input) do
    endpoint = fetch_model_endpoint!(input.model)
    content_type = content_type(input)

    with :ok <- validate_extension(input.filename),
         {:ok, file} <- File.read(input.filename),
         {:ok, response} <- request(:post, endpoint, file, content_type: content_type),
         {:ok, response} <- parse_response(response, filename: input.filename) do
      {:ok, response}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp request(:post, endpoint, body, opts) do
    headers = headers(opts)

    :post
    |> Finch.build(endpoint, headers, body)
    |> Finch.request(Ambiantcare.Finch, receive_timeout: 60_000 * 30)
  end

  defp parse_response(%Finch.Response{} = response, opts) do
    with response when response.status == 200 <- response,
         {:ok, body} <- Jason.decode(response.body),
         {:ok, response} <- Map.fetch(body, "text") do
      response = String.trim(response)
      {:ok, response}
    else
      :error ->
        {:error, decoding_error: "Failed to decode response #{inspect(response)}"}

      {:error, reason} ->
        {:error,
         decoding_error:
           "Failed to decode response #{inspect(response)} due to #{inspect(reason)}"}

      %Finch.Response{} = response when response.status != 200 ->
        filename = Keyword.get(opts, :filename)

        error = "Request failed with status #{response.status} and body #{response.body}"
        error = if filename, do: "#{error}, for filename #{filename}", else: error

        {:error, request_failed: error}
    end
  end

  defp fetch_model_endpoint!(model) do
    model = Map.fetch!(@dedicated_models_mapper, model)

    config()
    |> Keyword.fetch!(:model_endpoints)
    |> Keyword.fetch!(model)
  end
end
