defmodule VirtualCryptoWeb.V1.UserController do
  use VirtualCryptoWeb, :controller
  import Plug.Conn, only: [get_session: 2, halt: 1]

  def me(conn, params) do
    user = get_session(conn, :user)
    render(
      conn,
      "me.json",
      params: %{
        id: to_string(user.id),
        name: user.username,
        avatar: user.avatar,
        discriminator: user.discriminator
      }
    )
  end
end
