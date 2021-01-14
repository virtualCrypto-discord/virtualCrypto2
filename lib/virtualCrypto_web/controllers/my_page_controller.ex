defmodule VirtualCryptoWeb.MyPageController do
  use VirtualCryptoWeb, :controller

  plug VirtualCryptoWeb.AuthPlug when action in [:index]

  def index(conn, _) do
    user = conn.private.plug_session["user"]
    render conn, "me.html"
  end
end
