defmodule Clipboard.LLM.Backend do
  @moduledoc """
  The `Clipboard.LLM.Backend` behaviour defines the API that
  backends must implement in order to query LLMs.
  """
  @callback generate(model :: String.t(), prompt :: Stirng.t(), options :: Keyword.t()) ::
              {:ok, map()} | {:error, String.t()}
end
