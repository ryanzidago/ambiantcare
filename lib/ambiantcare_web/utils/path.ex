defmodule AmbiantcareWeb.Utils.Path do
  use AmbiantcareWeb, :verified_routes

  @spec medical_notes_path(locale :: String.t()) :: String.t()
  def medical_notes_path(locale \\ Gettext.get_locale(AmbiantcareWeb.Gettext)) do
    query_params = [
      huggingface_deployment: "dedicated",
      microphone_hook: "Microphone",
      stt_backend: "huggingface"
    ]

    ~p"/#{locale}/consultations?#{query_params}"
  end
end
