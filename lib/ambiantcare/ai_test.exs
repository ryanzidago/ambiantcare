defmodule Ambiantcare.AITest do
  use ExUnit.Case

  alias Ambiantcare.AI
  alias Ambiantcare.AI.Inputs.TextCompletion

  import Mox

  describe "generate with text_completion" do
    test "returns a response" do
      expect(Ambiantcare.AI.Backend.Mistral.Mock, :generate, fn %TextCompletion{} ->
        {:ok, "response"}
      end)

      text_completion = %TextCompletion{
        system_prompt_id: "medical_notes/v1_0",
        user_prompt: "Hello doctor, I have a headache."
      }

      assert {:ok, "response"} = AI.generate(text_completion)
    end
  end
end
