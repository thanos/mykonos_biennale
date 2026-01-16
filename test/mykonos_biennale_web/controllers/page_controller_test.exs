defmodule MykonosBiennaleWeb.PageControllerTest do
  use MykonosBiennaleWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "2025 — Anti-Mausoleum"
  end
end
