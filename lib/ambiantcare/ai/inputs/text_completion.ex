defmodule Ambiantcare.AI.Inputs.TextCompletion do
  use Ecto.Schema

  @extension ".toml"

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_text_completion_inputs" do
    field :backend, Ecto.Enum, values: [:huggingface, :mistral]
    field :model, :string
    field :system_prompt_id, :string
    field :system_prompt, :string
    field :user_prompt, :string
  end

  def build_input(%__MODULE__{} = text_completion) do
    filepath = Path.join(base_path(), text_completion.system_prompt_id) <> @extension

    case Toml.decode_file(filepath) do
      {:ok, config} ->
        system_prompt =
          config
          |> Map.fetch!("prompt")
          |> build_system_prompt()

        fields = [system_prompt: system_prompt, model: get_in(config, ~w(config model))]
        text_completion = struct!(text_completion, fields)

        {:ok, text_completion}

      {:error, error} ->
        {:error, error}
    end
  end

  defp build_system_prompt(%{"text" => text, "examples" => []}) do
    text
  end

  defp build_system_prompt(%{"text" => text, "examples" => examples}) do
    text <> "\n\n" <> Enum.map_join(examples, "\n", &build_example/1)
  end

  defp build_example(%{"input" => input, "output" => output}) do
    input <> "\n" <> output
  end

  defp priv_dir, do: :code.priv_dir(:ambiantcare)
  defp base_path, do: Path.join([priv_dir(), "prompts"])
end
