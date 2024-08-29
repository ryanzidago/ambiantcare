defmodule Clipboard.AI.HuggingFace do
  @audio_models ~w(openai/whisper-large-v3)
  @text_models ~w(meta-llama/Meta-Llama-3.1-8B-Instruct)

  @dedicated_models_mapper %{
    "openai/whisper-large-v3" => :open_ai_whisper_large_v3,
    "meta-llama/Meta-Llama-3.1-8B-Instruct" => :meta_llama31_8B_instruct
  }

  def generate(model, data, opts \\ [])

  def generate(model, filename, opts) when model in @audio_models do
    endpoint = maybe_dedicated_endpoint(model, opts)
    content_type = content_type(model, opts)

    with {:ok, file} <- File.read(filename),
         :ok <- validate_extension(filename),
         {:ok, response} <- request(:post, endpoint, file, content_type: content_type),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error -> error
    end
  end

  def generate(model, prompt, opts) when model in @text_models do
    endpoint = maybe_dedicated_endpoint(model, opts)
    content_type = content_type(model, opts)

    with {:ok, body} <- build_body(prompt, model, opts),
         {:ok, response} <- request(:post, endpoint, body, content_type: content_type),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error -> error
    end
  end

  defp validate_extension(filename) do
    extension = Path.extname(filename)

    if extension in expected_extensions() do
      :ok
    else
      {:error,
       invalid_extension:
         "Invalid file extension #{extension}, expected one of #{inspect(expected_extensions())}"}
    end
  end

  defp expected_extensions, do: ~w(.flac)

  defp build_body(prompt, model, options) do
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

  defp request(:post, endpoint, body, opts) do
    headers = headers(opts)

    :post
    |> Finch.build(endpoint, headers, body)
    |> Finch.request(Clipboard.Finch, receive_timeout: 60_000 * 10)
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

  defp maybe_dedicated_endpoint(model, opts) do
    dedicated_endpoint? = Keyword.get(opts, :is_dedicated, false)

    if dedicated_endpoint? do
      dedicated_endpoint(model)
    else
      config()[:serverless_endpoint] <> "/models/" <> model
    end
  end

  defp dedicated_endpoint(model) do
    model_key = Map.fetch!(@dedicated_models_mapper, model)

    _dedicated_endpoint =
      config()
      |> Keyword.fetch!(:dedicated_endpoints)
      |> Keyword.fetch!(model_key)
  end

  defp content_type(model, _opts) when model in @audio_models do
    "audio/flac"
  end

  defp content_type(model, opts) when model in @text_models do
    format = Keyword.get(opts, :format, "json")

    case format do
      "json" -> "application/json"
      _ -> "application/text"
    end
  end

  defp headers(opts) do
    content_type = Keyword.fetch!(opts, :content_type)

    [
      {"Authorization", "Bearer #{config()[:api_key]}"},
      {"Content-Type", content_type}
    ]
  end

  defp config do
    Application.get_env(:clipboard, HuggingFace)
  end
end
