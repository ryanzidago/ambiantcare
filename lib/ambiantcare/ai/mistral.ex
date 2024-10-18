defmodule Ambiantcare.AI.Mistral do
  @moduledoc """
  Mistral backend for LLM.
  """
  alias __MODULE__

  @agent_endpoint "/v1/agents/completions"
  @chat_completion_endpoint "/v1/chat/completions"

  @doc """
  Generates a response using the Mistral backend.
  """
  def generate(model, prompt, options)
      when is_binary(prompt) and is_binary(model) and is_list(options) do
    with {:ok, body} <- build_body(model, prompt, options),
         {:ok, response} <- request(:post, endpoint(model), body),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error ->
        error
    end
  end

  defp build_body("agent", prompt, options) do
    stream = Keyword.get(options, :stream, false)
    random_seed = Keyword.get(options, :random_seed, 0)

    messages = [
      %{
        "role" => "user",
        "content" => prompt
      }
    ]

    body =
      %{}
      |> Map.put("messages", messages)
      |> Map.put("stream", stream)
      |> Map.put("random_seed", random_seed)
      |> Map.put("agent_id", agent(:medical_note_agent_id))

    Jason.encode(body)
  end

  defp build_body(model, user_prompt, opts) do
    system_prompt = Keyword.fetch!(opts, :system_prompt)
    stream = Keyword.get(opts, :stream, false)
    temperature = Keyword.get(opts, :temperature, 0.0)
    response_format = Keyword.get(opts, :format, "json_object")

    messages = [
      %{
        "role" => "system",
        "content" => system_prompt
      },
      %{
        "role" => "user",
        "content" => user_prompt
      }
    ]

    body =
      %{}
      |> Map.put("model", model)
      |> Map.put("messages", messages)
      |> Map.put("stream", stream)
      |> Map.put("response_format", %{"type" => response_format})
      |> Map.put("temperature", temperature)

    Jason.encode(body)
  end

  defp endpoint("agent"), do: @agent_endpoint
  defp endpoint(_model), do: @chat_completion_endpoint

  defp request(:post, endpoint, body) do
    :post
    |> Finch.build(config()[:base_url] <> endpoint, headers(), body)
    |> Finch.request(Ambiantcare.Finch)
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
    Application.fetch_env!(:ambiantcare, Mistral)
  end

  defp headers do
    [
      {"content-type", "application/json"},
      {"accept", "application/json"},
      {"authorization", "Bearer #{config()[:api_key]}"}
    ]
  end

  defp agent(key) do
    config()
    |> Keyword.fetch!(:agents)
    |> Keyword.fetch!(key)
  end
end
