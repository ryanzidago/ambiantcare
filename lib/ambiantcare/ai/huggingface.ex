defmodule Ambiantcare.AI.HuggingFace do
  alias __MODULE__
  alias Ambiantcare.AI.HuggingFace.Serverless
  alias Ambiantcare.AI.HuggingFace.Dedicated

  def generate(model, data, opts \\ []) do
    deployment = Keyword.get(opts, :deployment, deployment())

    case deployment do
      :serverless -> Serverless.generate(model, data, opts)
      :dedicated -> Dedicated.generate(model, data, opts)
    end
  end

  defp config, do: Application.fetch_env!(:ambiantcare, HuggingFace)

  def deployment(%{"huggingface_deployment" => "serverless"}), do: :serverless
  def deployment(%{"huggingface_deployment" => "dedicated"}), do: :dedicated
  def deployment(_), do: deployment()

  def deployment do
    config()
    |> Keyword.fetch!(:deployment)
    |> String.to_existing_atom()
  end
end
