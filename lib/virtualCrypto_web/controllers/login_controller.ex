defmodule VirtualCryptoWeb.LoginController do
  use VirtualCryptoWeb, :controller

  plug VirtualCryptoWeb.AuthPlug when action in [:index]

  def index(conn, _params) do
    conn
    |> redirect(to: "/")
    |> halt()
  end
end
