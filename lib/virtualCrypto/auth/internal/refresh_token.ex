defmodule VirtualCrypto.Auth.InternalAction.RefreshToken do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import VirtualCrypto.Auth.InternalAction.Util
  import Ecto.Query

  def create_refresh_token(_grant_id, _lc \\ 5)

  def create_refresh_token(_grant_id, 0) do
    {:error, :retry_limit}
  end

  def create_refresh_token(grant_id, lc) do
    v =
      Repo.insert(
        %Auth.RefreshToken{
          grant_id: grant_id,
          token_id: Ecto.UUID.generate(),
          expires:
            NaiveDateTime.add(NaiveDateTime.utc_now(), 180 * 24 * 60 * 60)
            |> NaiveDateTime.truncate(:second)
        },
        conflict_target: [:grant_id],
        on_conflict: {:replace, [:token, :expires, :updated_at]},
        returns: true
      )

    case v do
      {:ok, %Auth.RefreshToken{id: nil}} ->
        case Repo.get(Auth.RefreshToken, grant_id: grant_id) do
          nil -> create_refresh_token(grant_id, lc - 1)
          v -> {:ok, v}
        end

      {:ok, v} ->
        {:ok, v}
    end
  end

  def replace_refresh_token(old_refresh_token, now \\ NaiveDateTime.utc_now()) do
    new_token = make_secure_random_code()

    q =
      from refresh_tokens in Auth.RefreshToken,
        select: [refresh_tokens.grant_id],
        where: refresh_tokens.token == ^old_refresh_token and refresh_tokens.expires >= ^now,
        update: [set: [token: ^new_token]]

    case Repo.update_all(q, []) do
      {0, _} -> {:error, :invalid_token}
      {1, [[grant_id]]} -> {:ok, %{grant_id: grant_id, token: new_token}}
    end
  end
end
