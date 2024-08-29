defmodule Clipboard.AI.Mistral do
  @moduledoc """
  Mistral backend for LLM.
  """

  @agent_endpoint "/v1/agents/completions"

  @doc """
  Generates a response using the Mistral backend.
  """
  def generate(model, prompt, options)
      when is_binary(prompt) and is_binary(model) and is_list(options) do
    with {:ok, body} <- build_body(prompt, model, options),
         {:ok, response} <- request(:post, @agent_endpoint, body),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error -> error
    end
  end

  defp build_body(prompt, _model, options) do
    # system_prompt = Keyword.get(options, :system_prompt)
    stream = Keyword.get(options, :stream, false)
    # format = Keyword.get(options, :format, "json")
    random_seed = Keyword.get(options, :random_seed, 0)

    messages = [
      # %{
      #   "role" => "system",
      #   "content" => system_prompt
      # },
      %{
        "role" => "user",
        "content" => prompt
      }
    ]

    # format = %{"type" => format}

    body =
      %{}
      |> Map.put("messages", messages)
      |> Map.put("stream", stream)
      # |> Map.put("response_format", format)
      |> Map.put("random_seed", random_seed)
      |> Map.put("agent_id", config()[:medical_note_agent_id])

    Jason.encode(body)
  end

  defp request(:post, endpoint, body) do
    :post
    |> Finch.build(config()[:base_url] <> endpoint, headers(), body)
    |> Finch.request(Clipboard.Finch)
  end

  defp parse_response(%Finch.Response{} = response) do
    with response when response.status == 200 <- response,
         {:ok, body} <- Jason.decode(response.body),
         {:ok, choices} <- Map.fetch(body, "choices"),
         [choice] <- choices,
         response <- get_in(choice, ~w(message content)),
         {:ok, response} <- Jason.decode(response) do
      {:ok, response}
    else
      {:error, reason} ->
        {:error,
         decoding_error:
           "Failed to decode response #{inspect(response)} due to #{inspect(reason)}"}

      %Finch.Response{} = response when response.status != 200 ->
        {:error,
         request_failed: "Request failed with status #{response.status} and body #{response.body}"}
    end
  end

  defp config do
    Application.fetch_env!(:clipboard, Mistral)
  end

  defp headers do
    [
      {"content-type", "application/json"},
      {"accept", "application/json"},
      {"authorization", "Bearer #{config()[:api_key]}"}
    ]
  end
end
