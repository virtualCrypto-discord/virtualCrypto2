defmodule VirtualCryptoWeb.MyPageController do
  use VirtualCryptoWeb, :controller

  plug VirtualCryptoWeb.AuthPlug when action in [:index]

  def index(conn, _) do
    render conn, "me.html"
  end
end
