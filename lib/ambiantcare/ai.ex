defmodule Ambiantcare.AI do
  alias Ambiantcare.AI.Inputs.TextCompletion
  alias Ambiantcare.AI.Inputs.SpeechToText
  alias Ambiantcare.AI.NumEx

  require Logger

  @spec generate(TextCompletion.t() | SpeechToText.t(), non_neg_integer()) ::
          {:ok, map()} | {:error, String.t()}
  def generate(input, retries_left \\ 3)

  def generate(%TextCompletion{} = input, retries_left) do
    input = struct!(input, backend: :mistral)

    with {:ok, input} <- TextCompletion.build_input(input),
         {:ok, response} <- mistral().generate(input) do
      {:ok, response}
    else
      {:error, %Mint.TransportError{reason: :timeout}} when retries_left > 0 ->
        Logger.error("Timeout error, retrying...")

        generate(input, retries_left: retries_left - 1)

      {:error, error} ->
        {:error, error}
    end
  end

  def generate(%SpeechToText{backend: :huggingface} = input, _retries_left) do
    with {:ok, response} <- huggingface().generate(input) do
      {:ok, response}
    else
      {:error, error} -> {:error, error}
    end
  end

  def generate(%SpeechToText{backend: :nx} = input, _retries_left) do
    NumEx.generate(input)
  end

  defp config, do: Application.get_env(:ambiantcare, __MODULE__)
  defp mistral, do: config()[:backends][:mistral]
  defp huggingface, do: config()[:backends][:huggingface]
end
