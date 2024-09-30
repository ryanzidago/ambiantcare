defmodule Ambiantcare.AI.HuggingFace.Serverless do
  import Ambiantcare.AI.HuggingFace.Helpers

  @audio_models audio_models()
  @text_models text_models()

  def generate(model, data, opts \\ [])

  def generate(model, filename, opts) when model in @audio_models do
    endpoint = config()[:serverless][:api_endpoint] <> "/" <> model
    content_type = content_type(model, opts)

    with :ok <- validate_extension(filename),
         {:ok, file} <- File.read(filename),
         {:ok, response} <- request(:post, endpoint, file, content_type: content_type),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error ->
        error
    end
  end

  def generate(model, prompt, opts) when model in @text_models do
    endpoint = config()[:serverless][:api_endpoint] <> "/" <> model
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
end
