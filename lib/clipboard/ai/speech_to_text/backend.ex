defmodule Clipboard.AI.SpeechToText.Backend do
  @moduledoc """
  The `Clipboard.AI.SpeechToText.Backend` behaviour defines the API that backends must implement in order to convert speech to text.
  """
  @callback generate(filename :: String.t(), options :: Keyword.t()) ::
              {:ok, String.t()} | {:error, String.t()}
end
