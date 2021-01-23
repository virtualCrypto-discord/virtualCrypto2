defmodule VirtualCrypto.DiscordAuth do
  alias VirtualCrypto.DiscordAuth
  alias VirtualCrypto.Repo
  alias VirtualCrypto.User
  import Ecto.Query

  defp update_token(discord_user_id, client) do
    token_data = Jason.decode!(client.token.access_token)

    {:ok, user} =
      update_user(
        user_id,
        token_data["token"],
        NaiveDateTime.add(NaiveDateTime.utc_now(), token_data["expires_in"]),
        token_data["refresh_token"]
      )

    user
  end

  def update_user(user_id, token, expires, refresh_token) do
    DiscordAuth.DiscordUser
    |> where([u], u.discord_user_id == ^user_id)
    |> update(
      set: [
        token: ^token,
        refresh_token: ^refresh_token,
        expires: ^(expires |> NaiveDateTime.truncate(:second))
      ]
    )
    |> Repo.update_all([])
  end

  def get_user_from_id(user_id) do
    DiscordAuth.DiscordUser
    |> where([u], u.discord_user_id == ^user_id)
    |> Repo.one()
  end

  def insert_user(discord_user_id, token, expires, refresh_token) do
    Repo.transaction(fn ->
      {:ok, vc} = User.insert_user_if_not_exists(discord_user_id)

      {:ok, discord} =
        Repo.insert(
          %DiscordAuth.DiscordUser{
            discord_user_id: discord_user_id,
            token: token,
            expires: expires |> NaiveDateTime.truncate(:second),
            refresh_token: refresh_token
          },
          on_conflict: :replace_all,
          conflict_target: :discord_user_id
        )

      %{virtual_crypto: vc, discord: discord}
    end)
  end

  def refresh_user(user_id) do
    case get_user_from_id(user_id) do
      nil ->
        nil

      user ->
        expire_time = NaiveDateTime.add(user.updated_at, 604_800)

        with true <- NaiveDateTime.diff(expire_time, NaiveDateTime.utc_now()) <= 60 * 15,
             {:ok, client} <- Discord.Api.V8.OAuth2.refresh_token(user.refresh_token) do
          update_token(user_id, client)
        else
          false -> user
          _ -> :error
        end
    end
  end

  def refresh_token(user) do
    case refresh_user(user.discord_user_id) do
      :ignore -> user
      new -> new
    end
  end
end
