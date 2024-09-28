defmodule ClipboardWeb.Sidebar do
  use ClipboardWeb, :live_component
  use Gettext, backend: ClipboardWeb.Gettext

  require Logger

  alias Clipboard.MedicalNotes.Template

  import ClipboardWeb.CoreComponents

  @known_locales Gettext.known_locales(ClipboardWeb.Gettext)

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{locale: locale}, socket) do
    socket =
      socket
      |> assign(locale: locale)
      |> assign_available_locale_options()
      |> assign_templates()
      |> assign_template_options()
      |> assign_template()

    {:ok, socket}
  end

  attr :locale_options, :list, required: true, doc: "The available locales"
  attr :locale, :string, required: true, doc: "The current locale"
  attr :template_options, :list, required: true, doc: "The available templates"
  attr :template, :map, required: true, doc: "The current template"

  @impl true
  def render(assigns) do
    ~H"""
    <aside
      id="default-sidebar"
      class="w-64 h-screen transition-transform -translate-x-full sm:translate-x-0"
      aria-label="Sidenav"
    >
      <div class="overflow-y-auto py-5 px-3 h-full bg-white border-r border-gray-200 dark:bg-gray-800 dark:border-gray-700">
        <ul class="space-y-2">
          <.branding />
          <.locale_setting locale_options={@locale_options} locale={@locale} phxtarget={@myself} />
          <.template_setting
            template_options={@template_options}
            template={@template}
            phxtarget={@myself}
          />
        </ul>
      </div>
    </aside>
    """
  end

  defp branding(assigns) do
    ~H"""
    <div class="justify-center p-4 rounded mb-20 shadow flex flex-row text-2x gap-0.5 drop-shadow-2xl font-semibold">
      <span class="text-blue-600">ambiant</span>
      <span class="bg-blue-600 px-2 rounded text-white">.Care</span>
    </div>
    """
  end

  defp locale_setting(assigns) do
    ~H"""
    <div>
      <.form for={%{}} phx-change="change_locale" as={:locale}>
        <.input
          type="select"
          name="locale"
          label={gettext("Language")}
          options={@locale_options}
          value={@locale}
        />
      </.form>
    </div>
    """
  end

  defp template_setting(assigns) do
    ~H"""
    <.form for={%{}} phx-change="change_template" as={:template}>
      <.input
        type="select"
        name="template_id"
        label={gettext("Template")}
        options={@template_options}
        value={@template.title}
      />
    </.form>
    """
  end

  defp assign_available_locale_options(socket) do
    locale_options =
      Enum.map(@known_locales, fn
        "en" -> {"English", "en"}
        "it" -> {"Italiano", "it"}
        _locale -> {"English", "en"}
      end)

    assign(socket, locale_options: locale_options)
  end

  defp assign_templates(socket) do
    templates = [Template.default_template(), Template.gastroenterology_template()]
    assign(socket, templates: templates)
  end

  defp assign_template_options(socket) do
    options = Enum.map(socket.assigns.templates, &{&1.title, &1.key})
    assign(socket, template_options: options)
  end

  defp assign_template(socket) do
    template = hd(socket.assigns.templates)
    assign(socket, template: template)
  end
end
