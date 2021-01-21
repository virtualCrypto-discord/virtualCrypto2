defmodule VirtualCrypto.Auth.InternalAction.AccessToken do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import VirtualCrypto.Auth.InternalAction.Util

  def create_access_token(_grant_id, _lc \\ 5)

  def create_access_token(_grant_id, 0) do
    {:error, :retry_limit}
  end

  def create_access_token(grant_id, lc) do
    v =
      Repo.insert(
        %Auth.AccessToken{
          grant_id: grant_id,
          token_id: Ecto.UUID.generate(),
          expires:
            NaiveDateTime.add(NaiveDateTime.utc_now(), 3600) |> NaiveDateTime.truncate(:second)
        },
        returns: true
      )

    case v do
      {:ok, %Auth.AccessToken{id: nil}} ->
        case Repo.get(Auth.AccessToken, grant_id: grant_id) do
          nil -> create_access_token(grant_id, lc - 1)
          v -> {:ok, v}
        end

      {:ok, v} ->
        {:ok, v}
    end
  end
end
