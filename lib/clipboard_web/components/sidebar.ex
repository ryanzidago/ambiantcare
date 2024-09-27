defmodule ClipboardWeb.Sidebar do
  use ClipboardWeb, :live_component
  use Gettext, backend: ClipboardWeb.Gettext

  import ClipboardWeb.CoreComponents

  @known_locales Gettext.known_locales(ClipboardWeb.Gettext)

  require Logger

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{locale: locale}, socket) do
    socket =
      socket
      |> assign_available_locale_options()
      |> assign(locale: locale)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <aside
      id="default-sidebar"
      class="w-64 h-screen transition-transform -translate-x-full sm:translate-x-0"
      aria-label="Sidenav"
    >
      <div class="overflow-y-auto py-5 px-3 h-full bg-white border-r border-gray-200 dark:bg-gray-800 dark:border-gray-700">
        <ul class="space-y-2">
          <.locale_selection locale_options={@locale_options} locale={@locale} phxtarget={@myself} />
        </ul>
      </div>
    </aside>
    """
  end

  defp locale_selection(assigns) do
    ~H"""
    <div>
      <.form for={%{}} phx-change="change_locale" phx-target={@phxtarget} as={:locale}>
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

  defp assign_available_locale_options(socket) do
    locale_options =
      Enum.map(@known_locales, fn
        "en" -> {"English", "en"}
        "it" -> {"Italiano", "it"}
        _locale -> {"English", "en"}
      end)

    assign(socket, locale_options: locale_options)
  end

  def handle_event("change_locale", %{"locale" => locale}, socket) do
    send(self(), {:change_locale, locale})
    {:noreply, socket}
  end
end
