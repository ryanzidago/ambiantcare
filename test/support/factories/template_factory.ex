defmodule Ambiantcare.Factories.TemplateFactory do
  alias Ambiantcare.MedicalNotes.Template

  defmacro __using__(_opts) do
    quote do
      def template_factory(attrs \\ %{}) do
        title = Map.get(attrs, :title, "A Random Template #{DateTime.utc_now()}")

        attrs =
          Template.default_template_attrs()
          |> Map.merge(attrs)
          |> Map.put(:title, title)

        Template
        |> struct!(attrs)
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
