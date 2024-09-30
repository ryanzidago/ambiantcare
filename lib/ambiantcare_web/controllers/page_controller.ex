defmodule AmbiantcareWeb.PageController do
  use AmbiantcareWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def index(conn, _params) do
    redirect(conn, to: ~p"/en")
  end
end
