defmodule VirtualCryptoWeb.LogoutController do
  use VirtualCryptoWeb, :controller

  plug VirtualCryptoWeb.AuthPlug when action in [:index]

  def index(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "ログアウトしました")
    |> redirect(to: "/")
    |> halt()
  end
end
