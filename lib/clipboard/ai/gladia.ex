defmodule Clipboard.AI.Gladia do
  require Logger

  @retry_delay_in_ms 1_000
  @max_retries 1 * 60 * 30

  def generate(_model, file_path, opts \\ []) do
    with {:ok, response} <- get_audio_url(file_path, opts),
         {:ok, response} <- get_result_url(response, opts),
         {:ok, transcription} <- get_result(response, _attempted = 0, opts) do
      {:ok, transcription}
    else
      {:error, _} = error -> error
    end
  end

  # upload audio file
  defp get_audio_url(file_path, opts) do
    with {:ok, response} <- request(:post_multipart, upload_endpoint(), file_path, opts),
         {:ok, body} <- parse_response(response) do
      {:ok, body}
    end
  end

  # get result url
  defp get_result_url(%{"audio_url" => audio_url} = _response, opts) do
    with {:ok, body} <- Jason.encode(%{"audio_url" => audio_url}),
         {:ok, response} <- request(:post, transcribe_endpoint(), body, opts),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    end
  end

  defp get_result(%{"result_url" => result_url} = _response, attempted, opts)
       when attempted < @max_retries do
    with {:ok, response} <- request(:get, result_url, opts),
         {:ok, body} <- parse_response(response),
         {:ok, full_transcript} <- parse_result(body) do
      {:ok, full_transcript}
    else
      {:retry, response} ->
        Logger.debug("Transcription is pending. Retrying in #{@retry_delay_in_ms}ms")
        Logger.debug(response)

        Process.sleep(@retry_delay_in_ms)

        get_result(%{"result_url" => result_url}, attempted + 1, opts)

      error ->
        error
    end
  end

  defp get_result(response, attempted, _opts) when attempted == @max_retries do
    Logger.error("Max retries exceeded")
    Logger.error(response)

    {:error, max_retries_exceeded: "Max retries exceeded"}
  end

  defp parse_result(%{"status" => "done"} = response) do
    with {:ok, result} <- Map.fetch(response, "result"),
         {:ok, transcription} <- Map.fetch(result, "transcription"),
         {:ok, full_transcript} <- Map.fetch(transcription, "full_transcript") do
      {:ok, full_transcript}
    end
  end

  defp parse_result(%{"status" => status} = response) when status in ~w(queued processing) do
    {:retry, response}
  end

  def request(:post_multipart, endpoint, file_path, _opts) do
    part = Multipart.Part.file_field(file_path, :audio)

    multipart =
      Multipart.new()
      |> Multipart.add_part(part)

    body_stream = Multipart.body_stream(multipart)
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")

    headers = [
      {"Content-Type", content_type},
      {"Content-Length", to_string(content_length)},
      {"x-gladia-key", api_key()}
    ]

    :post
    |> Finch.build(endpoint, headers, {:stream, body_stream})
    |> Finch.request(Clipboard.Finch, receive_timeout: 60_000 * 10)
  end

  def request(:post, endpoint, body, opts) do
    headers = headers(opts)

    :post
    |> Finch.build(endpoint, headers, body)
    |> Finch.request(Clipboard.Finch, receive_timeout: 60_000 * 10)
  end

  def request(:get, endpoint, opts) do
    headers = headers(opts)

    :get
    |> Finch.build(endpoint, headers)
    |> Finch.request(Clipboard.Finch, receive_timeout: 60_000 * 10)
  end

  defp parse_response(%Finch.Response{} = response) do
    with response when response.status in 200..201 <- response,
         {:ok, body} <- Jason.decode(response.body) do
      {:ok, body}
    else
      :error ->
        {:error, decoding_error: "Failed to decode response #{inspect(response)}"}

      {:error, reason} ->
        {:error,
         decoding_error:
           "Failed to decode response #{inspect(response)} due to #{inspect(reason)}"}

      %Finch.Response{} = response when response.status not in 200..201 ->
        {:error,
         request_failed: "Request failed with status #{response.status} and body #{response.body}"}
    end
  end

  defp headers(opts) do
    content_type = Keyword.get(opts, :content_type, "application/json")

    [
      {"Content-Type", content_type},
      {"x-gladia-key", api_key()}
    ]
  end

  defp api_key, do: config()[:api_key]
  defp base_url, do: config()[:base_url]

  defp upload_endpoint, do: Path.join(base_url(), "/upload")
  defp transcribe_endpoint, do: Path.join(base_url(), "/transcription")

  defp config do
    Application.get_env(:clipboard, __MODULE__)
  end
end
