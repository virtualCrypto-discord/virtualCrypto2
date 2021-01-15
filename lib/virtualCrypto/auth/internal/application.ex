defmodule VirtualCrypto.Auth.InternalAction.Application do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import Ecto.Query
  def register_client(
        grant_types,
        client_name,
        client_uri,
        logo_uri,
        owner_discord_id,
        discord_support_server_invite_slug,
        redirect_uris
      ) do
    v = %Auth.Application{
      status: 0,
      client_id: Ecto.UUID.generate(),
      client_secret: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false),
      response_types: [],
      grant_types: grant_types,
      application_type: "web",
      client_name: client_name,
      client_uri: client_uri,
      logo_uri: logo_uri,
      owner_discord_id: owner_discord_id,
      discord_support_server_invite_slug: discord_support_server_invite_slug
    }

    {:ok, app} = Repo.insert(v)

    Repo.insert_all(
      Auth.RedirectUri,
      redirect_uris
      |> Enum.map(fn redirect_uri ->
        %{
          application_id: app.id,
          redirect_uri: redirect_uri,
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end),
      on_conflict: :nothing
    )

    {:ok, app}
  end

  def get_application_by_client_id_and_verify_secret(client_id, client_secret) do
    v = get_application_by_client_id(client_id)

    case v do
      %Auth.Application{client_secret: ^client_secret} -> {:ok, v}
      %Auth.Application{client_secret: _} -> {:error, {:invalid_client, :invalid_secret}}
      nil -> {:error, {:invalid_client, :client_not_found}}
    end
  end

  def validate_redirect_uri(application_id, redirect_uri) do
    q =
      from u in Auth.RedirectUri,
        where: u.application_id == ^application_id and u.redirect_uri == ^redirect_uri

    Repo.exists?(q)
  end

  def get_application_by_client_id(client_id) do
    case Ecto.UUID.cast(client_id) do
      {:ok,client_id} -> Repo.get_by(Auth.Application, client_id: client_id)
      :error -> nil
    end
  end
end
