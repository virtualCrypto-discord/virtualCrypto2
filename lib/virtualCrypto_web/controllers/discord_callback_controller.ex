defmodule VirtualCryptoWeb.DiscordCallbackController do
  use VirtualCryptoWeb, :controller
  import Plug.Conn, only: [halt: 1, put_session: 3]

  defp save_token(conn, client) do
    token_data = Jason.decode!(client.token.access_token)
    token = token_data["access_token"]
    refresh_token = token_data["refresh_token"]
    user_data = Discord.Api.V8.Oauth2.get_user_info(client, token)
    user_id = String.to_integer(user_data["id"])
    response = VirtualCrypto.Auth.insert_user(
      user_id,
      token,
      refresh_token
    )
    conn
    |> put_session(
         :user,
         %{
           id: user_id,
           username: user_data["username"],
           avatar: user_data["avatar"],
           discriminator: user_data["discriminator"]
         }
       )
    |> put_flash(:info, "ログイン成功しました")
    |> redirect(to: "/")
    |> halt()
  end

  def index(conn, _params) do
    case Discord.Api.V8.Oauth2.exchange_code(_params["code"]) do
      :error ->
        conn
        |> put_flash(:error, "Invalid code!")
        |> redirect(to: "/")
        |> halt()
      client -> save_token(conn, client)
    end
  end
end
