defmodule AmbiantcareWeb.PageController do
  use AmbiantcareWeb, :controller

  alias AmbiantcareWeb.Utils.PathUtils

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def index(conn, _params) do
    locale = get_locale(conn)
    redirect(conn, to: ~p"/#{locale}")
  end

  def medical_notes(conn, _params) do
    path =
      conn
      |> get_locale()
      |> PathUtils.consultations_path()

    redirect(conn, to: path)
  end
end
