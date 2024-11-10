defmodule Ambiantcare.AI.Backend do
  @type text_completion :: Ambiantcare.AI.Inputs.TextCompletion
  @type speech_to_text :: Ambiantcare.AI.Inputs.SpeechToText
  @type input :: text_completion() | speech_to_text()
  @callback generate(input()) :: {:ok, map()} | {:error, String.t()}
end
