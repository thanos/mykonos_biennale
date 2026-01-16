defmodule MykonosBiennaleWeb.RedirectController do
  use MykonosBiennaleWeb, :controller

  def redirect_to_posts(conn, _params) do
    conn
    |> Phoenix.Controller.redirect(to: ~p"/admin/pages")
    |> Plug.Conn.halt()
  end
end
