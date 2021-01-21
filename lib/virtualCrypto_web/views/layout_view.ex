defmodule VirtualCryptoWeb.LayoutView do
  use VirtualCryptoWeb, :view

  def is_logged_in?(conn) do
    conn.private.plug_session["user"] != nil
  end
end
