defmodule Ambiantcare.Factories.MedicalNoteFactory do
  alias Ambiantcare.MedicalNotes.MedicalNote

  defmacro __using__(_opts) do
    quote do
      def medical_note_factory(attrs \\ %{}) do
        user = Map.get_lazy(attrs, :user, fn -> insert(:user) end)

        consultation =
          Map.get_lazy(attrs, :consultation, fn -> insert(:consultation, user: user) end)

        template = Map.get_lazy(attrs, :template, fn -> insert(:template, user: user) end)

        fields =
          Map.get(attrs, :fields, [
            %{"name" => :chief_complaint, "label" => "Chief Complaint", "value" => "Headache"}
          ])

        MedicalNote
        |> struct!(%{user: user, consultation: consultation, template: template, fields: fields})
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
