defmodule AmbiantcareWeb.UserLocale do
  import Plug.Conn, only: [get_session: 2, put_session: 3]

  @doc """
  Gets the locale from the conn's parameter, if not from the conn's sesssion, if not, from Gettext.
  """
  @spec get_locale(Plug.Conn.t() | map() | any()) :: String.t()
  def get_locale(%Plug.Conn{} = conn) do
    Map.get(conn.params, "locale") ||
      get_session(conn, :locale) ||
      Gettext.get_locale(AmbiantcareWeb.Gettext)
  end

  def get_locale(%{} = params) when is_map(params) do
    Map.get(params, "locale") ||
      Map.get(params, :locale) ||
      Gettext.get_locale(AmbiantcareWeb.Gettext)
  end

  def get_locale(_), do: Gettext.get_locale(AmbiantcareWeb.Gettext)

  @doc """
  Puts the locale into the conn's session and Gettext.
  Useful for controllers.
  """
  @spec put_locale(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def put_locale(%Plug.Conn{} = conn, _opts = []) do
    locale = get_locale(conn)
    Gettext.put_locale(AmbiantcareWeb.Gettext, locale)
    put_session(conn, :locale, locale)
  end
end
