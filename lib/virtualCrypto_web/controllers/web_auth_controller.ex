defmodule VirtualCryptoWeb.WebAuthController do
  use VirtualCryptoWeb, :controller

  import Plug.Conn,
    only: [
      halt: 1,
      put_session: 3,
      configure_session: 2,
      get_session: 2,
      delete_session: 2,
      put_resp_header: 3,
      fetch_session: 2
    ]

  defp get_continue_uri_from_session(conn) do
    case get_session(conn, :discord_oauth2).continue do
      nil -> "/"
      url -> url
    end
  end

  defp issue_token(id) do
    {:ok, access_token, %{"exp" => expires}} =
      VirtualCrypto.Guardian.issue_token_for_user(id, ["oauth2.register", "vc.pay", "vc.claim"])

    {:ok, access_token, DateTime.diff(DateTime.from_unix!(expires), DateTime.utc_now())}
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

    {:ok, access_token, expires_in} = issue_token(vc.id)

    redirect_to = get_continue_uri_from_session(conn)

    conn
    |> put_session(
      :user,
      %{
        id: vc.id
      }
    )
    |> put_resp_header("x-access-token", access_token)
    |> put_resp_header("x-redirect-to", redirect_to)
    |> put_resp_header("x-expires-in", to_string(expires_in))
    |> put_flash(:info, "ログイン成功しました")
    |> delete_session(:discord_oauth2)
    |> configure_session(renew: true)
    |> render("index.html",
      access_token: access_token,
      redirect_to: redirect_to,
      expires_in: expires_in
    )
  end

  def discord_callback(conn, %{"state" => state, "code" => code}) do
    case get_session(conn, :discord_oauth2) do
      %{state: ^state} ->
        case Discord.Api.V8.OAuth2.exchange_code(code) do
          :error ->
            conn
            |> configure_session(drop: true)
            |> put_flash(:error, "Invalid code!")
            |> redirect(to: "/")
            |> halt()

          client ->
            save_token(conn, client)
        end

      _ ->
        conn
        |> configure_session(drop: true)
        |> put_flash(:error, "Invalid state!")
        |> redirect(to: "/")
        |> halt()
    end
  end

  plug :fetch_session when action in [:token]

  def token(conn, _) do
    case get_session(conn, :user) do
      %{id: id} ->
        {:ok, access_token, expires_in} = issue_token(id)
        render(conn, "token.json", access_token: access_token, expires_in: expires_in)

      _ ->
        nil
    end
  end
end
