defmodule VirtualCryptoWeb.MyPageController do
  use VirtualCryptoWeb, :controller

  def index(conn, _) do
    render(conn, "me.html")
  end
end
