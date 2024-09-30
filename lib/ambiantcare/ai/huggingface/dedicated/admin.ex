defmodule Ambiantcare.AI.HuggingFace.Dedicated.Admin do
  @moduledoc """
  API for managing dedicated Hugging Face endpoints (AI models deployed on a provider's server).
  """

  import Ambiantcare.AI.HuggingFace.Helpers, only: [headers: 1]

  def list_endpoints do
    api_endpoint = config()[:api_endpoint] <> "/endpoint/" <> config()[:namespace]
    response = request(:get, api_endpoint, [])

    with {:ok, %Finch.Response{} = response} when response.status in 200..300 <- response,
         {:ok, body} <- Jason.decode(response.body),
         {:ok, endpoints} <- Map.fetch(body, "items") do
      {:ok, endpoints}
    else
      {:ok, %Finch.Response{} = response} -> {:error, response}
      {:error, _} = error -> error
    end
  end

  def resume(endpoint) do
    api_endpoint = config()[:api_endpoint] <> "/endpoint/" <> config()[:namespace]
    endpoint = "#{api_endpoint}/#{endpoint}/resume"
    response = request(:post, endpoint, "", [])

    with {:ok, %Finch.Response{} = response} <- response,
         {:ok, body} <- Jason.decode(response.body),
         %{"status" => %{"state" => "pending"}} = body <- body do
      {:ok, body}
    else
      %{"error" => "Bad Request: Endpoint is already running"} ->
        {:ok, "Endpoint is already running"}

      {:error, _} = error ->
        error
    end
  end

  def resume_all do
    with {:ok, endpoints} <- list_endpoints(),
         :ok <- do_resume_all(endpoints) do
      :ok
    else
      {:error, _} = error -> error
    end
  end

  defp do_resume_all(endpoints) do
    Enum.reduce_while(endpoints, :ok, fn endpoint, :ok ->
      case resume(endpoint["name"]) do
        {:ok, _} -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp config do
    :ambiantcare
    |> Application.fetch_env!(Ambiantcare.AI.HuggingFace)
    |> Keyword.fetch!(:dedicated)
  end

  defp request(:get, endpoint, opts) do
    headers = headers(opts)

    :get
    |> Finch.build(endpoint, headers)
    |> Finch.request(Ambiantcare.Finch, receive_timeout: 60_000 * 10)
  end

  defp request(:post, endpoint, body, opts) do
    headers = headers(opts)

    :post
    |> Finch.build(endpoint, headers, body)
    |> Finch.request(Ambiantcare.Finch, receive_timeout: 60_000 * 10)
  end
end
