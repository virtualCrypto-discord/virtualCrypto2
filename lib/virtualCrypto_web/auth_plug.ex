defmodule VirtualCryptoWeb.AuthPlug do
  import Plug.Conn, only: [get_session: 2, halt: 1,put_session: 3]
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts), do: opts

  defp start_discord_login(conn) do
    state = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    conn
    |> put_session(:discord_oauth2_state,state)
    |> redirect(external: Discord.Api.V8.Oauth2.authorize_url(state))
    |> halt()
  end
  def call(conn, _opts) do
    case get_session(conn, :user) do
      nil ->
        start_discord_login(conn)
      user ->
        case VirtualCrypto.Auth.refresh_user(user.id) do
          nil ->
            start_discord_login(conn)
          _ -> conn
        end
    end
  end
end
