defmodule VirtualCryptoWeb.MyPageController do
  use VirtualCryptoWeb, :controller

  plug VirtualCryptoWeb.AuthPlug when action in [:index]

  def index(conn, _) do
    user = conn.private.plug_session["user"]
    render(conn,
           "me.html",
           user: user.id,
           balance: VirtualCrypto.Money.balance(user: user.id))
  end
end
