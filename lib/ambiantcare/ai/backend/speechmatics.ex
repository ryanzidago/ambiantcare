defmodule Ambiantcare.AI.SpeechMatics do
  require Logger

  # @ryanzidago - 30 minutes of retries
  @retry_delay_in_ms 1_000
  @max_retries 1 * 60 * 30

  def generate(_model, filename, opts \\ []) do
    with {:ok, response} <- create_job(filename, opts),
         {:ok, response} <- get_job_details(response, _attempted = 0),
         {:ok, transcription} <- get_transcription(response, opts),
         {:ok, transcription} <- parse_transcription(transcription) do
      {:ok, transcription}
    else
      {:error, _} = error -> error
    end
  end

  defp create_job(filename, opts) do
    locale = Keyword.get(opts, :locale, "en")
    opts = [locale: locale]

    with {:ok, response} <- request(:post_multipart, job_endpoint(), filename, opts),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error -> error
    end
  end

  defp get_job_details(%{"id" => job_id} = response, attempted) when attempted < @max_retries do
    with {:ok, response} <- request(:get, job_endpoint(job_id), []),
         {:ok, response} <- parse_response(response),
         {:done, response} <- parse_job_status(response) do
      {:ok, response}
    else
      {:running, details} ->
        Logger.debug("Job is pending. Retrying in #{@retry_delay_in_ms}ms")
        Logger.debug(details)

        Process.sleep(@retry_delay_in_ms)

        get_job_details(response, attempted + 1)

      {:error, _} = error ->
        error
    end
  end

  defp get_job_details(response, attempted) when attempted == @max_retries do
    Logger.error("Max retries exceeded")
    Logger.error(response)

    {:error, max_retries_exceeded: "Max retries exceeded"}
  end

  defp get_transcription(%{"job" => %{"id" => job_id}} = _response, opts) do
    with {:ok, response} <- request(:get, transcript_endpoint(job_id), opts),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error -> error
    end
  end

  defp parse_transcription(%{} = transcription) do
    path = ["results", Access.all(), "alternatives", Access.all(), "content"]

    parsed_transcription =
      transcription
      |> get_in(path)
      |> Enum.reduce("", fn [word], acc ->
        if(word =~ ~r/[[:punct:]]/, do: acc <> word, else: acc <> " " <> word)
      end)
      |> String.trim()

    {:ok, parsed_transcription}
  end

  defp request(:post_multipart, endpoint, file_path, opts) do
    locale = Keyword.fetch!(opts, :locale)

    config =
      Jason.encode!(%{
        type: "transcription",
        transcription_config: %{
          operating_point: "enhanced",
          language: locale
        }
      })

    file = Multipart.Part.file_field(file_path, :data_file)
    config = Multipart.Part.text_field(config, :config)

    multipart =
      Multipart.new()
      |> Multipart.add_part(file)
      |> Multipart.add_part(config)

    body_stream = Multipart.body_stream(multipart)
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")

    headers = [
      {"Content-Type", content_type},
      {"Content-Length", to_string(content_length)},
      {"Authorization", "Bearer " <> api_key()}
    ]

    :post
    |> Finch.build(endpoint, headers, {:stream, body_stream})
    |> Finch.request(Ambiantcare.Finch, receive_timeout: 60_000 * 10)
  end

  defp request(:post, endpoint, body, opts) do
    headers = headers(opts)

    :post
    |> Finch.build(endpoint, headers, body)
    |> Finch.request(Ambiantcare.Finch, receive_timeout: 60_000 * 10)
  end

  defp request(:get, endpoint, opts) do
    headers = headers(opts)

    :get
    |> Finch.build(endpoint, headers)
    |> Finch.request(Ambiantcare.Finch, receive_timeout: 60_000 * 10)
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

  defp parse_job_status(%{"job" => %{"status" => "done"}} = response) do
    {:done, response}
  end

  defp parse_job_status(%{"job" => %{"status" => "running"}} = response) do
    {:running, response}
  end

  defp parse_job_status(%{"job" => %{"status" => status}} = _response) do
    {:error, "Job status is #{status}"}
  end

  defp headers(opts) do
    content_type = Keyword.get(opts, :content_type, "application/json")

    [
      {"Content-Type", content_type},
      {"Authorization", "Bearer " <> api_key()}
    ]
  end

  defp transcript_endpoint(job_id), do: job_endpoint(job_id) <> "/transcript"

  defp job_endpoint(job_id \\ nil),
    do: base_url() <> "/jobs" <> if(job_id, do: "/" <> job_id, else: "")

  defp api_key, do: config()[:api_key]
  defp base_url, do: config()[:base_url]
  defp config, do: Application.fetch_env!(:ambiantcare, Ambiantcare.AI.SpeechMatics)
end
