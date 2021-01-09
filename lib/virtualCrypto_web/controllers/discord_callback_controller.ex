defmodule VirtualCryptoWeb.DiscordCallbackController do
  use VirtualCryptoWeb, :controller
  import Plug.Conn, only: [halt: 1]

  def index(conn, _params) do
    conn
    |> redirect(to: "/")
    |> halt()
  end
end
