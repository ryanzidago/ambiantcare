defmodule AmbiantcareWeb.Sidebar do
  @moduledoc """
  https://flowbite.com/docs/components/sidebar/#default-sidebar
  """
  use AmbiantcareWeb, :live_component
  use Gettext, backend: AmbiantcareWeb.Gettext

  require Logger

  alias Ambiantcare.MedicalNotes.Template

  alias AmbiantcareWeb.Components.Branding

  import AmbiantcareWeb.CoreComponents

  @known_locales Gettext.known_locales(AmbiantcareWeb.Gettext)

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
    <div class="flex flex-col gap-2">
      <button
        type="button"
        class="inline-flex items-center p-2 mt-2 ms-3 text-sm w-10 rounded-lg hover:bg-gray-100 focus:outline-none dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
        phx-click={
          JS.toggle_class(
            "hidden sm:block",
            to: "#default-sidebar",
            transition: "",
            time: 0
          )
        }
      >
        <span class="sr-only">Open sidebar</span>
        <svg
          class="w-6 h-6"
          aria-hidden="true"
          fill="currentColor"
          viewBox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            clip-rule="evenodd"
            fill-rule="evenodd"
            d="M2 4.75A.75.75 0 012.75 4h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 4.75zm0 10.5a.75.75 0 01.75-.75h7.5a.75.75 0 010 1.5h-7.5a.75.75 0 01-.75-.75zM2 10a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 10z"
          >
          </path>
        </svg>
      </button>

      <aside id="default-sidebar" class="w-44 h-screen hidden sm:visible" aria-label="Sidenav">
        <div class="overflow-y-auto py-5 px-3 h-full bg-white border-r border-gray-200 dark:bg-gray-800 dark:border-gray-700">
          <Branding.logo class="mb-20" />
          <div class="flex flex-col gap-2">
            <.locale_setting locale_options={@locale_options} locale={@locale} phxtarget={@myself} />
            <.template_setting
              template_options={@template_options}
              template={@template}
              phxtarget={@myself}
            />
          </div>
        </div>
      </aside>
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
