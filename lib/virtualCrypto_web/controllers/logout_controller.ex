defmodule VirtualCryptoWeb.LogoutController do
  use VirtualCryptoWeb, :controller

  plug VirtualCryptoWeb.AuthPlug when action in [:index]

  def index(conn, _params) do
    conn
    |> delete_session(:user)
    |> put_flash(:info, "ログアウトしました")
    |> redirect(to: "/")
    |> halt()
  end
end
