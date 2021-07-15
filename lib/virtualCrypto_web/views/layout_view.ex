defmodule VirtualCryptoWeb.LayoutView do
  use VirtualCryptoWeb, :view
  import Plug.Conn, only: [get_session: 2]

  def is_logged_in?(conn) do
    get_session(conn, :user) != nil
  end
end
