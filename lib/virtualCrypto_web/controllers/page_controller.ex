defmodule VirtualCryptoWeb.PageController do
  use VirtualCryptoWeb, :controller
  import Plug.Conn, only: [get_session: 2, halt: 1]

  def index(conn, _params) do
    VirtualCrypto.Auth.refresh_user(get_session(conn, :user).id)
    render(conn, "index.html")
  end
end
