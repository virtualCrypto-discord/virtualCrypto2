defmodule VirtualCryptoWeb.V1.UserController do
  use VirtualCryptoWeb, :controller

  def me(conn, _params) do
    case Guardian.Plug.current_token(conn) do
      nil ->
        {:error}

      token ->
        {:ok, %{"sub" => user_id}} = VirtualCrypto.Guardian.decode_and_verify(token)
        user = VirtualCrypto.User.get_user_by_id(user_id)
        discord_user_authz_info = VirtualCrypto.DiscordAuth.refresh_user(user.discord_id)
        discord_user = Discord.Api.V8.OAuth2.get_user_info(discord_user_authz_info.token)
        render(
          conn,
          "me.json",
          params: %{
            id: to_string(discord_user["id"]),
            name: discord_user["username"],
            avatar: discord_user["avatar"],
            discriminator: discord_user["discriminator"]
          }
        )
    end
  end
end
