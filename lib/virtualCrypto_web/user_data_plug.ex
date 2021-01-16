defmodule VirtualCryptoWeb.UserDataPlug do
  import Plug.Conn, only: [get_session: 2, assign: 3]

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user) do
      nil ->
        conn
        |> assign(:logged_in, false)
      user ->
        VirtualCrypto.Auth.refresh_user(user.id)
        conn
        |> assign(:logged_in, true)
        |> assign(:user_id, user.id)
        |> assign(:user_name, user.username)
        |> assign(:user_discriminator, user.discriminator)
    end
  end
end
