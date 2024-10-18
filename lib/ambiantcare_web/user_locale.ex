defmodule AmbiantcareWeb.UserLocale do
  import Plug.Conn, only: [get_session: 2]

  @doc """
  Gets the locale from the conn's parameter, if not from the conn's sesssion, if not, from Gettext.
  """
  @spec get_locale(Plug.Conn.t()) :: String.t()
  def get_locale(%Plug.Conn{} = conn) do
    Map.get(conn.params, "locale") ||
      get_session(conn, :locale) ||
      Gettext.get_locale(AmbiantcareWeb.Gettext)
  end

  def get_locale(_), do: Gettext.get_locale(AmbiantcareWeb.Gettext)
end
