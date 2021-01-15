defmodule VirtualCrypto.Auth.InternalAction.Grant do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import Ecto.Query

  def get_or_create_grant_if_not_reused(application_id, guild_id, latest_code) do
    q = from(grants in Auth.Grant, where: grants.latest_code == ^latest_code)

    case Repo.delete_all(q) do
      {0, _} ->
        Repo.insert(
          %Auth.Grant{
            application_id: application_id,
            guild_id: guild_id,
            latest_code: latest_code
          },
          on_conflict: [set: [latest_code: latest_code]],
          conflict_target: [:application_id, :guild_id],
          returning: true
        )

      {_cnt, _} ->
        {:error, :invalid_code}
    end
  end

  def create_grant_scopes(grant_id, scopes) do
    Repo.insert_all(
      Auth.GrantScope,
      scopes
      |> Enum.map(fn scope ->
        %{
          grant_id: grant_id,
          scope: scope,
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end),
      on_conflict: :nothing
    )
  end
end
