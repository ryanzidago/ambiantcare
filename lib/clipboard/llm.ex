defmodule Clipboard.LLM do
  alias Clipboard.LLM.Backends.Ollama
  alias Clipboard.LLM.Backends.Mistral
  alias Clipboard.LLM.Backends.Huggingface

  @backends_mapper %{
    ollama: Ollama,
    mistral: Mistral,
    huggingface: Huggingface
  }

  def generate(%{} = attrs) do
    with {:ok, backend} <- fetch_backend(attrs),
         {:ok, model} <- fetch_model(attrs),
         {:ok, prompt} <- fetch_prompt(attrs),
         options <- Map.get(attrs, :options, []),
         {:ok, response} <- apply(backend, :generate, [model, prompt, options]) do
      {:ok, response}
    else
      {:error, _} = error -> error
    end
  end

  defp fetch_backend(%{} = attrs) do
    with {:ok, backend} <- Map.fetch(attrs, :backend),
         {:ok, backend} <- Map.fetch(@backends_mapper, backend) do
      {:ok, backend}
    else
      :error -> {:error, missing_backend: "`backend` is missing"}
      _ -> {:error, invalid_backend: "Expected one of: #{Enum.join(@backends_mapper, ", ")}"}
    end
  end

  defp fetch_model(%{} = attrs) do
    case Map.fetch(attrs, :model) do
      {:ok, model} -> {:ok, model}
      :error -> {:error, missing_model: "`model` is missing"}
    end
  end

  defp fetch_prompt(%{} = attrs) do
    case Map.fetch(attrs, :prompt) do
      {:ok, prompt} -> {:ok, prompt}
      :error -> {:error, missing_prompt: "`prompt` is missing"}
    end
  end
end
