defmodule VirtualCrypto.User do
  alias VirtualCrypto.Repo
  import Ecto.Query

  def insert_user_if_not_exists(discord_id) when is_integer(discord_id) do
    with {:ok, nil} <- {:ok, Repo.get_by(VirtualCrypto.User.User, discord_id: discord_id)},
         {:ok, %VirtualCrypto.User.User{id: nil}} <-
           Repo.insert(%VirtualCrypto.User.User{discord_id: discord_id, status: 0},
             on_conflict: :nothing
           ) do
      {:ok, Repo.get_by(VirtualCrypto.User.User, discord_id: discord_id)}
    end
  end

  def insert_users_if_not_exists(discord_ids) when is_list(discord_ids) do
    time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    {_, _} =
      Repo.insert_all(
        VirtualCrypto.User.User,
        discord_ids
        |> Enum.map(&%{discord_id: &1, status: 0, inserted_at: time, updated_at: time}),
        on_conflict: :nothing,
        conflict_target: [:discord_id]
      )

    q =
      from users in VirtualCrypto.User.User,
        where: users.discord_id in ^discord_ids

    {:ok, Repo.all(q)}
  end

  def get_user_by_id(id) do
    Repo.get_by(VirtualCrypto.User.User, id: id)
  end

  def get_users_by_id(ids) do
    q =
      from users in VirtualCrypto.User.User,
        where: users.id in ^ids

    Repo.all(q)
  end
end
