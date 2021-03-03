defmodule VirtualCrypto.Auth do
  alias VirtualCrypto.Auth.InternalAction, as: Action
  alias VirtualCrypto.Repo
  import Ecto.Query

  @spec register_application(%{
          optional(:application_type) => String.t(),
          optional(:grant_types) => [String.t()],
          optional(:client_name) => String.t(),
          optional(:client_uri) => String.t(),
          optional(:logo_uri) => String.t(),
          required(:owner_discord_id) => non_neg_integer(),
          optional(:discord_support_server_invite_slug) => String.t(),
          required(:redirect_uris) => [String.t()]
        }) ::
          {:ok, Ecto.Schema.t()}
          | {:error, any()}
  def register_application(info) do
    {:ok, data} =
      Action.Application.register_client(
        Map.get(info, :application_type, "web"),
        Map.get(info, :grant_types, []),
        Map.get(info, :client_name),
        Map.get(info, :client_uri),
        Map.get(info, :logo_uri),
        info.owner_discord_id,
        Map.get(info, :discord_support_server_invite_slug),
        info.redirect_uris
      )

    {:ok, user} = Repo.insert(%VirtualCrypto.User.User{application_id: data.application.id})
    {:ok, data |> Map.put(:user, user)}
  end

  defp run(f) do
    case Repo.transaction(fn ->
           case f.() do
             {:ok, v} -> v
             {:commit, v} -> {:commit, v}
             {:error, v} -> Repo.rollback(v)
             v -> Repo.rollback(v)
           end
         end) do
      {:ok, {:commit, v}} -> v
      v -> v
    end
  end

  @spec preauthorize(%{
          scopes: [String.t()],
          redirect_uri: String.t(),
          client_id: String.t()
        }) ::
          {:ok, nil}
          | {:error, :invalid_redirect_uri}
          | {:error, :invalid_client_id}
          | {:error, :invalid_grant_type}
          | {:error, :invalid_scope}
  def preauthorize(info) do
    run(fn ->
      Action.validate_authorization_request_and_get_application_info(
        info.scopes,
        info.redirect_uri,
        info.client_id
      )
    end)
  end

  @spec authorize(%{
          guild_id: non_neg_integer(),
          scopes: [String.t()],
          redirect_uri: String.t(),
          client_id: String.t()
        }) ::
          {:ok,
           %{
             code: String.t(),
             scopes: [String.t()]
           }}
          | {:error, :invalid_redirect_uri}
          | {:error, :invalid_client_id}
          | {:error, :invalid_grant_type}
  def authorize(info) do
    run(fn ->
      Action.make_code(
        info.guild_id,
        info.scopes,
        info.redirect_uri,
        info.client_id
      )
    end)
  end

  @spec issue_unbound_code(%{
          guild_id: non_neg_integer(),
          scopes: [String.t()]
        }) ::
          {:ok,
           %{
             code: String.t()
           }}
  def issue_unbound_code(info) do
    run(fn ->
      Action.AuthorizationCode.make_unbound_code(
        info.guild_id,
        info.scopes
      )
    end)
  end

  @spec exchange_token_by_unbound_authroization_code(%{
          client_id: String.t(),
          client_secret: String.t(),
          code: String.t()
        }) ::
          {:ok,
           %{
             access_token: String.t(),
             refresh_token: String.t(),
             token_type: String.t(),
             expires_in: non_neg_integer()
           }}
          | {:error, :invalid_code}
          | {:error, :invalid_client_id}
          | {:error, :invalid_secret}
          | {:error, :invalid_grant_type}
  def exchange_token_by_unbound_authroization_code(info) do
    run(fn ->
      Action.token_unbound_authorization_code(
        info.client_id,
        info.client_secret,
        info.code,
        NaiveDateTime.utc_now()
      )
    end)
  end

  @spec exchange_token_by_authroization_code(%{
          client_id: String.t(),
          redirect_uri: String.t(),
          code: String.t()
        }) ::
          {:ok,
           %{
             access_token: String.t(),
             refresh_token: String.t(),
             token_type: String.t(),
             expires_in: non_neg_integer()
           }}
          | {:error, :invalid_code}
          | {:error, :invalid_client_id}
          | {:error, :invalid_redirect_uri}
  def exchange_token_by_authroization_code(info) do
    run(fn ->
      Action.token_authorization_code(
        info.client_id,
        info.code,
        info.redirect_uri,
        NaiveDateTime.utc_now()
      )
    end)
  end

  @spec exchange_token_by_refresh_token(%{token: String.t()}) ::
          {:ok,
           %{
             access_token: String.t(),
             refresh_token: String.t(),
             token_type: String.t(),
             expires_in: non_neg_integer()
           }}
          | {:error, :invalid_token}
  def exchange_token_by_refresh_token(info) do
    run(fn ->
      Action.token_refresh_token(info.token)
    end)
  end

  def exchange_token_by_client_credentials(info) do
    run(fn ->
      Action.token_client_credentials(info.client_id, info.client_secret, info.guild_id)
    end)
  end

  @spec is_valid_access_token?(%{
          optional(:guild_id) => String.t(),
          required(:token) => String.t()
        }) :: boolean()
  def is_valid_access_token?(info) do
    guild_id = Map.get(info, :guild_id)

    if guild_id == nil do
      Action.is_valid_access_token?(info.token)
    else
      Action.is_valid_access_token?(info.token, guild_id)
    end
  end

  def get_application(application_id) do
    case Repo.transaction(fn ->
           Action.Application.get_application_and_redirect_uri_by_application_id(application_id)
         end) do
      {:ok, r} -> r
    end
  end

  def get_user_applications(user_id) do
    q =
      from application in VirtualCrypto.Auth.Application,
        left_join: redirect_uris in VirtualCrypto.Auth.RedirectUri,
        on: redirect_uris.application_id == application.id,
        join: owner_users in VirtualCrypto.User.User,
        join: application_users in VirtualCrypto.User.User,
        on:
          owner_users.id == ^user_id and owner_users.discord_id == application.owner_discord_id and
            application_users.application_id == application.id,
        select: {application, application_users, redirect_uris}

    Repo.all(q)
  end

  def get_user_application(user_id, id) do
    q =
      from application in VirtualCrypto.Auth.Application,
        left_join: redirect_uris in VirtualCrypto.Auth.RedirectUri,
        on: redirect_uris.application_id == application.id,
        join: owner_users in VirtualCrypto.User.User,
        join: application_users in VirtualCrypto.User.User,
        on:
          owner_users.id == ^user_id and owner_users.discord_id == application.owner_discord_id and
            application_users.application_id == application.id,
        where: application.client_id == ^id,
        select: {application, application_users, redirect_uris}

    r = Repo.all(q)

    if r == [] do
      nil
    else
      h = hd(r)
      {elem(h, 0), elem(h, 1), r |> Enum.map(&elem(&1, 2)) |> Enum.filter(&(&1 != nil))}
    end
  end

  def get_application_user_id_by_client_id(client_id, client_secret) do
    q =
      from applications in VirtualCrypto.Auth.Application,
        join: users in VirtualCrypto.User.User,
        on:
          applications.client_id == ^client_id and applications.client_secret == ^client_secret and
            users.application_id == applications.id,
        select: {users.id}

    case Repo.one(q) do
      {id} -> id
      nil -> nil
    end
  end

  def purge_user_access_tokens(time \\ NaiveDateTime.utc_now()) do
    q =
      from tokens in VirtualCrypto.Auth.UserAccessToken,
        where:
          tokens.expires <=
            ^(time |> NaiveDateTime.add(-5 * 60, :second) |> NaiveDateTime.truncate(:second))
    Repo.delete_all(q)
  end
  def purge_access_tokens(time \\ NaiveDateTime.utc_now()) do
    q =
      from tokens in VirtualCrypto.Auth.AccessToken,
        where:
          tokens.expires <=
            ^(time |> NaiveDateTime.add(-5 * 60, :second) |> NaiveDateTime.truncate(:second))
    Repo.delete_all(q)
  end
end
