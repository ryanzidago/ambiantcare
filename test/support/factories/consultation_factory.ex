defmodule Ambiantcare.Factories.ConsultationFactory do
  alias Ambiantcare.Consultations.Consultation

  defmacro __using__(_opts) do
    quote do
      def consultation_factory(attrs \\ %{}) do
        title = Map.get(attrs, :title, "A Consultation")
        transcription = Map.get(attrs, :transcription, "Hello doctor, I am sick!")
        context = Map.get(attrs, :context, "The patient is a middle-aged male.")
        start_datetime = Map.get(attrs, :start_datetime, ~U[2024-10-27 10:00:00Z])
        end_datetime = Map.get(attrs, :end_datetime, ~U[2024-10-27 10:30:00Z])
        user = Map.get_lazy(attrs, :user, fn -> insert(:user) end)

        consultation = %Consultation{
          title: title,
          transcription: transcription,
          context: context,
          start_datetime: start_datetime,
          end_datetime: end_datetime
        }

        consultation
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
