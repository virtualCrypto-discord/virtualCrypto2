defmodule VirtualCryptoWeb.LayoutView do
  use VirtualCryptoWeb, :view

  def is_login(conn) do
    conn.private.plug_session["user"] != nil
  end

  def get_username(conn) do
    if is_login conn do
      conn.private.plug_session["user"].username
    else
      ""
    end
  end

  def get_user_id(conn) do
    if is_login conn do
      conn.private.plug_session["user"].id
    else
      ""
    end
  end

  def get_user_avatar(conn) do
    if is_login conn do
      conn.private.plug_session["user"].avatar
    else
      ""
    end
  end
end
