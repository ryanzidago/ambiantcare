defmodule Ambiantcare.Factories.MedicalNoteFactory do
  alias Ambiantcare.MedicalNotes.MedicalNote

  defmacro __using__(_opts) do
    quote do
      def medical_note_factory(attrs \\ %{}) do
        user = Map.get_lazy(attrs, :user, fn -> insert(:user) end)

        consultation =
          Map.get_lazy(attrs, :consultation, fn -> insert(:consultation, user: user) end)

        template = Map.get_lazy(attrs, :template, fn -> insert(:template, user: user) end)

        MedicalNote
        |> struct!(%{})
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
