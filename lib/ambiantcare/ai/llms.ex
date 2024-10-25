defmodule Ambiantcare.AI.LLMs do
  @extension ".toml"
  @temperature 0.0

  def generate(filepath, user_prompt) when is_binary(filepath) and is_binary(user_prompt) do
    filepath = Path.join(base_path(), filepath) <> @extension

    case Toml.decode_file(filepath) do
      {:ok, config} ->
        generate(config, user_prompt)

      {:error, error} ->
        {:error, error}
    end
  end

  def generate(
        %{
          "config" =>
            %{
              "backend" => "mistral"
            } = config,
          "prompt" => prompt
        } = _parameters,
        user_prompt
      ) do
    model = Map.get(config, "model")
    temperature = Map.get(config, "temperature", @temperature)
    system_prompt = build_system_prompt(prompt)

    opts = [system_prompt: system_prompt, temperature: temperature]

    Ambiantcare.AI.Mistral.generate(model, user_prompt, opts)
  end

  def build_system_prompt(%{"text" => text, "examples" => []}) do
    text
  end

  def build_system_prompt(%{"text" => text, "examples" => examples}) do
    text <> "\n\n" <> Enum.map_join(examples, "\n", &build_example/1)
  end

  defp build_example(%{"input" => input, "output" => output}) do
    input <> "\n" <> output
  end

  defp priv_dir, do: :code.priv_dir(:ambiantcare)
  defp base_path, do: Path.join([priv_dir(), "prompts"])
end
