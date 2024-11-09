defmodule Ambiantcare.AI.Backend.Mistral do
  @moduledoc """
  Mistral backend for LLM.
  """
  alias Ambiantcare.AI
  alias Ambiantcare.AI.Inputs.TextCompletion

  @behaviour AI.Backend

  @agent_endpoint "/v1/agents/completions"
  @chat_completion_endpoint "/v1/chat/completions"

  @doc """
  Generates a response using the Mistral backend.
  """
  @impl AI.Backend
  def generate(%TextCompletion{} = input) do
    input = maybe_put_default_values(input)

    with {:ok, body} <- build_body(input),
         {:ok, response} <- request(:post, endpoint(input), body),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, _} = error ->
        error
    end
  end

  defp maybe_put_default_values(%TextCompletion{} = input) do
    %TextCompletion{
      input
      | backend: :huggingface,
        model: input.model || "mistral-small-latest"
    }
  end

  defp build_body(%TextCompletion{model: "agent"} = input) do
    messages = [
      %{
        "role" => "user",
        "content" => input.user_prompt
      }
    ]

    body =
      %{}
      |> Map.put("messages", messages)
      |> Map.put("stream", false)
      |> Map.put("random_seed", 0)
      |> Map.put("agent_id", agent(:medical_note_agent_id))

    Jason.encode(body)
  end

  defp build_body(%TextCompletion{} = input) do
    messages = [
      %{
        "role" => "system",
        "content" => input.system_prompt
      },
      %{
        "role" => "user",
        "content" => input.user_prompt
      }
    ]

    body =
      %{}
      |> Map.put("model", input.model)
      |> Map.put("messages", messages)
      |> Map.put("stream", false)
      |> Map.put("response_format", %{"type" => "json_object"})
      |> Map.put("temperature", 0.0)

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
    Application.fetch_env!(:ambiantcare, __MODULE__)
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
