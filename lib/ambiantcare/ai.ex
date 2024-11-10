defmodule Ambiantcare.AI do
  alias Ambiantcare.AI.Inputs.TextCompletion
  alias Ambiantcare.AI.Inputs.SpeechToText

  @spec generate(TextCompletion.t() | SpeechToText.t()) :: {:ok, map()} | {:error, String.t()}
  def generate(%TextCompletion{} = input) do
    input = struct!(input, backend: :mistral)

    with {:ok, input} <- TextCompletion.build_input(input),
         {:ok, response} <- mistral().generate(input) do
      {:ok, response}
    else
      {:error, error} -> {:error, error}
    end
  end

  def generate(%SpeechToText{} = input) do
    with {:ok, response} <- huggingface().generate(input) do
      {:ok, response}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp config, do: Application.get_env(:ambiantcare, __MODULE__)
  defp mistral, do: config()[:backends][:mistral]
  defp huggingface, do: config()[:backends][:huggingface]
end
