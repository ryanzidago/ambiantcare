defmodule AmbiantcareWeb.PageControllerTest do
  use AmbiantcareWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/en")
    assert html_response(conn, 200) =~ "Ambiantcare"
  end
end
