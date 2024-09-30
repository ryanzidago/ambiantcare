defmodule Ambiantcare.AI.Ollama do
  @moduledoc """
  The `Ambiantcare.AI.Ollama` module implements the `Ambiantcare.AI.LLM.Backend` for the Ollama API.
  """

  @generate_endpoint "/api/generate"
  @headers [
    {"content-type", "application/json"},
    {"accept", "application/json"}
  ]

  @spec generate(model :: binary(), prompt :: binary(), options :: list()) ::
          {:ok, map()} | {:error, binary()}
  def generate(model, prompt, options)
      when is_binary(prompt) and is_binary(model) and is_list(options) do
    with {:ok, body} <- build_body(prompt, model, options),
         {:ok, response} <- request(:post, @generate_endpoint, body),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

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

  defp request(:post, endpoint, body) do
    :post
    |> Finch.build(config()[:base_url] <> endpoint, @headers, body)
    |> Finch.request(Ambiantcare.Finch)
  end

  defp parse_response(%Finch.Response{} = response) do
    with response when response.status == 200 <- response,
         {:ok, body} <- Jason.decode(response.body),
         {:ok, response} <- Map.fetch(body, "response"),
         {:ok, response} <- Jason.decode(response) do
      {:ok, response}
    else
      {:error, reason} ->
        {:error, "Failed to decode response #{inspect(response)} due to  #{inspect(reason)}"}

      %Finch.Response{} = response when response.status != 200 ->
        {:error, "Request failed with status #{response.status} #{inspect(response)}"}
    end
  end

  defp config do
    :ambiantcare
    |> Application.fetch_env!(Ambiantcare.AI.Ollama)
    |> Keyword.fetch!(:backends)
    |> Keyword.fetch!(:ollama)
  end
end
