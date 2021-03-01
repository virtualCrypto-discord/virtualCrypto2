defmodule VirtualCrypto.User do
  alias VirtualCrypto.Repo
  import Ecto.Query

  def insert_user_if_not_exists(discord_id) do
    with {:ok, nil} <- {:ok, Repo.get_by(VirtualCrypto.User.User, discord_id: discord_id)},
         {:ok, %VirtualCrypto.User.User{id: nil}} <-
           Repo.insert(%VirtualCrypto.User.User{discord_id: discord_id, status: 0},
             on_conflict: :nothing
           ) do
      {:ok, Repo.get_by(VirtualCrypto.User.User, discord_id: discord_id)}
    end
  end

  def get_user_by_id(id) do
    Repo.get_by(VirtualCrypto.User.User, id: id)
  end

  def set_discord_user_id(application_id, discord_id) do
    VirtualCrypto.User.User
    |> where([u], u.application_id == ^application_id)
    |> update(set: [discord_id: ^discord_id])
    |> Repo.update_all([])
  end
end
