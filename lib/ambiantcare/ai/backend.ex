defmodule Ambiantcare.AI.Backend do
  @type text_completion :: Ambiantcare.AI.Inputs.TextCompletion
  @type input :: text_completion()
  @callback generate(input()) :: {:ok, map()} | {:error, String.t()}
end
