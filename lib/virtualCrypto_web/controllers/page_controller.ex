defmodule VirtualCryptoWeb.PageController do
  use VirtualCryptoWeb, :controller
  import Plug.Conn, only: [get_session: 2, halt: 1]

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
