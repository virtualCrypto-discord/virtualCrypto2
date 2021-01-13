defmodule VirtualCrypto.Auth.InternalAction.AuthorizationCode do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import Ecto.Query
  import VirtualCrypto.Auth.InternalAction.Util

  def make_unbound_code(discord_guild_id, scopes) do
    code = make_secure_random_code()

    v = %Auth.AuthorizationCode{
      code: code,
      redirect_uri: nil,
      application_id: nil,
      guild_id: discord_guild_id,
      scopes: scopes,
      expires:
        NaiveDateTime.add(NaiveDateTime.utc_now(), 15 * 60) |> NaiveDateTime.truncate(:second)
    }

    case Repo.insert(v) do
      {:ok, _} -> %{code: code}
      v -> v
    end
  end



  def get_and_delete_unbound_authorization_code(code) do
    q =
      from authorization_codes in Auth.AuthorizationCode,
        where: authorization_codes.code == ^code,
        select: [
          authorization_codes.application_id,
          authorization_codes.guild_id,
          authorization_codes.scopes,
          authorization_codes.expires
        ]

    case Repo.delete_all(q) do
      {0, _} ->
        nil

      {1, [[application_id, guild_id, scopes, expires]]} ->
        %{application_id: application_id, guild_id: guild_id, scopes: scopes, expires: expires}
    end
  end
end
