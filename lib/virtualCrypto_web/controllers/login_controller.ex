defmodule VirtualCryptoWeb.LoginController do
  use VirtualCryptoWeb, :controller

  plug VirtualCryptoWeb.AuthPlug when action in [:index]

  def index(conn, _params) do
    conn
    |> put_flash(:info, "ログイン成功しました")
    |> redirect(to: "/")
    |> halt()
  end
end
