defmodule VirtualCryptoWeb.DiscordCallbackController do
  use VirtualCryptoWeb, :controller

  import Plug.Conn,
    only: [
      halt: 1,
      put_session: 3,
      configure_session: 2,
      get_session: 2,
      delete_session: 2,
      put_resp_header: 3
    ]

  defp get_continue_uri_from_session(conn) do
    case get_session(conn, :discord_oauth2).continue do
      nil -> "/"
      url -> url
    end
  end

  defp save_token(conn, client) do
    token_data = Jason.decode!(client.token.access_token)
    token = token_data["access_token"]
    expires = NaiveDateTime.add(NaiveDateTime.utc_now(), token_data["expires_in"])
    refresh_token = token_data["refresh_token"]
    user_data = Discord.Api.V8.OAuth2.get_user_info(token)
    discord_user_id = String.to_integer(user_data["id"])

    {:ok, %{virtual_crypto: vc}} =
      VirtualCrypto.DiscordAuth.insert_user(
        discord_user_id,
        token,
        expires,
        refresh_token
      )

    {:ok, access_token, _} = VirtualCrypto.Guardian.encode_and_sign(%{id: vc.id})
    conn
    |> put_session(
      :user,
      %{
        # This is discord user id
        id: vc.id
      }
    )
    |> put_resp_header("x-access-token", access_token)
    |> put_resp_header("x-redirect-to", get_continue_uri_from_session(conn))
    |> put_flash(:info, "ログイン成功しました")
    |> delete_session(:discord_oauth2)
    |> configure_session(renew: true)
    |> render("index.html", access_token: access_token)
  end

  def index(conn, %{"state" => state, "code" => code}) do
    case get_session(conn,:discord_oauth2) do
      %{state: ^state} ->
        case Discord.Api.V8.OAuth2.exchange_code(code) do
          :error ->
            conn
            |> put_flash(:error, "Invalid code!")
            |> configure_session(drop: true)
            |> redirect(to: "/")
            |> halt()
          client ->
            save_token(conn,client)
        end

      _ ->
        conn
        |> put_flash(:error, "Invalid state!")
        |> configure_session(drop: true)
        |> redirect(to: "/")
        |> halt()
    end
  end
end
