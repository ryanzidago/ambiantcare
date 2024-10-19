defmodule AmbiantcareWeb.Hooks.SetLocale do
  @moduledoc """
  Module responsible for setting the locale in LiveViews.
  """
  import Phoenix.Component, only: [assign: 2]
  import Phoenix.LiveView, only: [redirect: 2]

  alias Phoenix.LiveView.Socket

  @known_locales Gettext.known_locales(AmbiantcareWeb.Gettext)

  def on_mount(:default, %{"locale" => locale} = url_params, _session, socket)
      when locale in @known_locales do
    Gettext.put_locale(AmbiantcareWeb.Gettext, locale)
    {:cont, assign(socket, url_params: url_params, locale: locale)}
  end

  # catch-all case
  def on_mount(:default, _params, _session, socket), do: {:cont, socket}

  @doc """
  Sets the locale and redirects to the given path to refresh the LiveView with the new locale.
  """
  @spec set(socket :: Socket.t(), locale :: String.t(), path :: String.t()) :: :ok
  def set(%Socket{} = socket, locale, path) when locale in @known_locales do
    Gettext.put_locale(AmbiantcareWeb.Gettext, locale)

    path =
      socket.assigns.url_params
      |> Map.put("locale", locale)
      |> path_from_url_params(path)

    redirect(socket, to: path)
  end

  defp path_from_url_params(%{} = url_params, path) do
    {locale, params} = Map.pop!(url_params, "locale")
    encoded_query = URI.encode_query(params)

    _path =
      ["/", locale, path]
      |> Path.join()
      |> URI.new!()
      |> URI.append_query(encoded_query)
      |> URI.to_string()
  end
end
