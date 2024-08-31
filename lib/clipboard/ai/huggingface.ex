defmodule Clipboard.AI.HuggingFace do
  alias __MODULE__
  alias Clipboard.AI.HuggingFace.Serverless
  alias Clipboard.AI.HuggingFace.Dedicated

  def generate(model, data, opts \\ []) do
    deployment = Keyword.get(opts, :deployment, deployment(:deployment))

    case deployment do
      :serverless -> Serverless.generate(model, data, opts)
      :dedicated -> Dedicated.generate(model, data, opts)
    end
  end

  defp config, do: Application.fetch_env!(:clipboard, HuggingFace)

  defp deployment(key) do
    config()
    |> Keyword.fetch!(key)
    |> String.to_existing_atom()
  end
end
