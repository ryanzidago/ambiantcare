defmodule AmbiantcareWeb.Utils.PathUtils do
  use AmbiantcareWeb, :verified_routes

  alias Ambiantcare.Consultations.Consultation

  @spec consultations_path(locale :: String.t()) :: String.t()
  def consultations_path(locale \\ Gettext.get_locale(AmbiantcareWeb.Gettext)) do
    ~p"/#{locale}/consultations?#{query_params()}"
  end

  @spec consultation_path(consultation :: Consultation.t() | Ecto.UUID.t(), locale :: String.t()) ::
          String.t()
  def consultation_path(consultation, locale \\ Gettext.get_locale(AmbiantcareWeb.Gettext))

  def consultation_path(%Consultation{} = consultation, locale) do
    consultation_path(consultation.id, locale)
  end

  def consultation_path(consultation_id, locale) do
    ~p"/#{locale}/consultations/#{consultation_id}?#{query_params()}"
  end

  @spec query_params() :: Keyword.t()
  def query_params do
    [
      microphone_hook: "Microphone",
      stt_backend: "huggingface"
    ]
  end
end
