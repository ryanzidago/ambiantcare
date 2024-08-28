defmodule Clipboard.AI.SpeechToText.Backends.HuggingFace do
  @behaviour Clipboard.AI.SpeechToText.Backend

  @endpoint "/models"

  @impl true
  def generate(model, filename, _opts \\ []) when is_binary(model) and is_binary(filename) do
    with {:ok, file} <- File.read(filename),
         :ok <- validate_extension(filename),
         {:ok, response} <- request(:post, @endpoint <> "/" <> model, file),
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

  defp request(:post, endpoint, body) do
    :post
    |> Finch.build(config()[:base_url] <> endpoint, headers(), body)
    |> Finch.request(Clipboard.Finch)
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

  defp headers do
    [
      {"Authorization", "Bearer #{config()[:api_key]}"},
      {"Content-Type", "application/octet-stream"}
    ]
  end

  def config do
    :clipboard
    |> Application.get_env(Clipboard.AI.SpeechToText)
    |> Keyword.get(:backends)
    |> Keyword.get(:huggingface)
  end
end
