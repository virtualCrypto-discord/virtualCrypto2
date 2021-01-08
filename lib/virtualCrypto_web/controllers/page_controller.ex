defmodule VirtualCryptoWeb.PageController do
  use VirtualCryptoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
