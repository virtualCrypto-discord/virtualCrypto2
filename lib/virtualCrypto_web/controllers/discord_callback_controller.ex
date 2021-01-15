defmodule VirtualCryptoWeb.DiscordCallbackController do
  use VirtualCryptoWeb, :controller
  import Plug.Conn, only: [halt: 1, put_session: 3,configure_session: 2,get_session: 2,delete_session: 2]

  defp save_token(conn, client) do
    token_data = Jason.decode!(client.token.access_token)
    token = token_data["access_token"]
    refresh_token = token_data["refresh_token"]
    user_data = Discord.Api.V8.Oauth2.get_user_info(client, token)
    user_id = String.to_integer(user_data["id"])
    {:ok, jwt, _} = VirtualCrypto.Guardian.encode_and_sign(%{id: user_id})
    VirtualCrypto.Auth.insert_user(
      user_id,
      token,
      refresh_token
    )
    conn
    |> put_session(
         :user,
         %{
           # This is discord user id
           id: user_id,
           username: user_data["username"],
           avatar: user_data["avatar"],
           discriminator: user_data["discriminator"]
         }
       )
    |> put_session(:jwt, jwt)
    |> put_flash(:info, "ログイン成功しました")
    |> configure_session(renew: true)
    |> redirect(to: "/")
    |> halt()
  end

  def index(conn, %{"state" => state, "code" => code}) do
    case conn|>get_session(:discord_oauth2_state) do
      ^state ->
        case Discord.Api.V8.Oauth2.exchange_code(code) do
          :error ->
            conn
            |> put_flash(:error, "Invalid code!")
            |> redirect(to: "/")
            |> halt()
          client -> save_token(conn, client)
        end
      _ ->
        conn
        |> put_flash(:error, "Invalid state!")
        |> redirect(to: "/")
        |> halt()
    end
    conn |> delete_session(:discord_oauth2_state)
  end
end
