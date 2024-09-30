defmodule Ambiantcare.AI.HuggingFace.Dedicated do
  import Ambiantcare.AI.HuggingFace.Helpers

  @audio_models audio_models()
  @text_models text_models()

  @dedicated_models_mapper %{
    "openai/whisper-large-v3" => :open_ai_whisper_large_v3,
    "meta-llama/Meta-Llama-3.1-8B-Instruct" => :meta_llama_3_1_8B_instruct
  }

  def generate(model, data, opts \\ [])

  def generate(model, filename, opts) when model in @audio_models do
    endpoint = fetch_model_endpoint!(model)
    content_type = content_type(model, opts)

    with :ok <- validate_extension(filename),
         {:ok, file} <- File.read(filename),
         {:ok, response} <- request(:post, endpoint, file, content_type: content_type),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error -> error
    end
  end

  def generate(model, prompt, opts) when model in @text_models do
    endpoint = fetch_model_endpoint!(model)
    content_type = content_type(model, opts)

    with {:ok, body} <- build_body(prompt, model, opts),
         {:ok, response} <- request(:post, endpoint, body, content_type: content_type),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error -> error
    end
  end

  defp request(:post, endpoint, body, opts) do
    headers = headers(opts)

    :post
    |> Finch.build(endpoint, headers, body)
    |> Finch.request(Ambiantcare.Finch, receive_timeout: 60_000 * 10)
  end

  defp parse_response(%Finch.Response{} = response) do
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
        {:error,
         request_failed: "Request failed with status #{response.status} and body #{response.body}"}
    end
  end

  defp fetch_model_endpoint!(model) do
    model = Map.fetch!(@dedicated_models_mapper, model)

    config()
    |> Keyword.fetch!(:dedicated)
    |> Keyword.fetch!(:model_endpoints)
    |> Keyword.fetch!(model)
  end
end
