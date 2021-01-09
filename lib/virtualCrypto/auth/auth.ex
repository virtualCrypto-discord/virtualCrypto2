defmodule VirtualCrypto.Auth do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import Ecto.Query

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
      }, on_conflict: :nothing
    )
  end
end
