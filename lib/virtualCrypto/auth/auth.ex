defmodule VirtualCrypto.Auth do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import Ecto.Query

  defp update_token(user_id, client) do
    token_data = Jason.decode!(client.token.access_token)
    {:ok, user} = update_user user_id, token_data["token"], token_data["refresh_token"]

    user
  end

  def update_user(user_id, token, refresh_token) do
    Auth.DiscordUser
    |> where([u], u.discord_user_id == ^user_id)
    |> update(set: [token: ^token, refresh_token: ^refresh_token])
    |> Repo.update_all([])
  end

  def get_user_from_id(user_id) do
    Auth.DiscordUser
    |> where([u], u.discord_user_id == ^user_id)
    |> Repo.one
  end

  def insert_user(user_id, token, refresh_token) do
    Repo.insert(
      %Auth.DiscordUser{
        discord_user_id: user_id,
        token: token,
        refresh_token: refresh_token,
      }, on_conflict: :replace_all, conflict_target: :discord_user_id
    )
  end

  def refresh_user(user_id) do
    user = get_user_from_id user_id
    expire_time = NaiveDateTime.add(user.updated_at, 604800)
    with true <- NaiveDateTime.diff(expire_time, NaiveDateTime.utc_now()) <= 0,
      {:ok, client} <- Discord.Api.V8.Oauth2.refresh_token(user.refresh_token) do
        update_token(user_id, client)
    else
      _ -> :ignore
    end
  end

  def refresh_token(user) do
    case refresh_user user.discord_user_id do
      :ignore -> user
      new -> new
    end
  end
end
