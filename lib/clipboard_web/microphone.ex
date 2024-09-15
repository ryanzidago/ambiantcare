defmodule ClipboardWeb.Microphone do
  @microphone_hooks ~w(Microphone StreamMicrophone)

  @spec from_params(map()) :: String.t()
  def from_params(%{"microphone_hook" => microphone_hook} = _params)
      when microphone_hook in @microphone_hooks do
    microphone_hook
  end

  def from_params(_params), do: "StreamMicrophone"
end
