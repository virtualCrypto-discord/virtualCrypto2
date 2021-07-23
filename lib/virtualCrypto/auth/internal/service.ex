defmodule VirtualCrypto.Auth.InternalAction do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import Ecto.Query
  import VirtualCrypto.Auth.InternalAction.Util
  alias VirtualCrypto.Auth.InternalAction, as: Action

  defp create_refresh_token_if_application_use(application, grant) do
    if Enum.member?(application.grant_types, "refresh_token") do
      Action.RefreshToken.create_refresh_token(grant.id)
    else
      {:ok, nil}
    end
  end

  def make_code(discord_guild_id, scopes, redirect_uri, client_id) do
    code = make_secure_random_code()

    expires =
      NaiveDateTime.add(NaiveDateTime.utc_now(), 15 * 60) |> NaiveDateTime.truncate(:second)

    with {:get_application, app} when app != nil <-
           {:get_application, Action.Application.get_application_by_client_id(client_id)},
         {:validate_redirect_uri, true} <-
           {:validate_redirect_uri,
            Action.Application.validate_redirect_uri(app.id, redirect_uri)},
         {:validate_application_grant_type, true} <-
           {:validate_application_grant_type,
            app.grant_types |> Enum.member?("authorization_code")},
         {:validate_scopes, true} <- {:validate_scopes, is_valid_scopes?(scopes)} do
      v = %Auth.AuthorizationCode{
        code: code,
        redirect_uri: redirect_uri,
        application_id: app.id,
        guild_id: discord_guild_id,
        scopes: scopes,
        expires: expires
      }

      case Repo.insert(v) do
        {:ok, _} ->
          {:ok,
           %{
             code: code,
             scopes: scopes,
             redirect_uri: redirect_uri,
             expires: expires,
             guild_id: discord_guild_id
           }}

        v ->
          v
      end
    else
      {:get_application, nil} ->
        {:error, :invalid_client_id}

      {:validate_redirect_uri, false} ->
        {:error, :invalid_redirect_uri}

      {:validate_application_grant_type, false} ->
        {:error, {:invalid_request, :unauthorized_client}}

      {:validate_scopes, false} ->
        {:error, :invalid_scope}
    end
  end

  @spec token_unbound_authorization_code(String.t(), String.t(), String.t(), NaiveDateTime.t()) ::
          {:ok, map()} | {:error, any()}
  def token_unbound_authorization_code(
        client_id,
        client_secret,
        code,
        now \\ NaiveDateTime.utc_now()
      ) do
    with {:get_and_delete_unbound_authorization_code, authorization_code}
         when authorization_code != nil <-
           {:get_and_delete_unbound_authorization_code,
            Action.AuthorizationCode.get_and_delete_unbound_authorization_code(code)},
         {:code_expiration, :gt} <-
           {:code_expiration, NaiveDateTime.compare(authorization_code.expires, now)},
         {:ok, application} <-
           Action.Application.get_application_by_client_id_and_verify_secret(
             client_id,
             client_secret
           ),
         {:validate_application_grant_type, true} <-
           {:validate_application_grant_type,
            application.grant_types |> Enum.member?("unbound_authorization_code")},
         {:ok, grant} <-
           Action.Grant.get_or_create_grant_if_not_reused(
             application.id,
             authorization_code.guild_id,
             code
           ),
         _ <- Action.Grant.create_grant_scopes(grant.id, authorization_code.scopes),
         {:ok, access_token} <- Action.AccessToken.create_access_token(grant.id),
         {:ok, refresh_token} <- create_refresh_token_if_application_use(application, grant) do
      v =
        if refresh_token == nil do
          %{
            access_token: access_token.token,
            token_type: "Bearer",
            expires_in: 3600,
            scopes: authorization_code.scopes
          }
        else
          %{
            access_token: access_token.token,
            token_type: "Bearer",
            expires_in: 3600,
            refresh_token: refresh_token.token,
            scopes: authorization_code.scopes
          }
        end

      {:ok, v}
    else
      {:get_and_delete_unbound_authorization_code, _} -> {:error, :invalid_code}
      {:code_expiration, _} -> {:error, :invalid_code}
      {:validate_application_grant_type, _} -> {:error, :invalid_grant_type}
      {:error, _} = err -> err
    end
  end

  def token_authorization_code(
        client_id,
        code,
        redirect_uri,
        now \\ NaiveDateTime.utc_now()
      ) do
    case Action.AuthorizationCode.get_and_delete_unbound_authorization_code(code) do
      nil ->
        q = from(grants in Auth.Grant, where: grants.latest_code == ^code)

        case Repo.delete_all(q) do
          {0, _} -> {:error, {:invalid_grant, :invalid_code}}
          {_cnt, _} -> {:commit, {:error, {:invalid_grant, :used_code}}}
        end

      authorization_code ->
        with {:code_expiration, :gt} <-
               {:code_expiration, NaiveDateTime.compare(authorization_code.expires, now)},
             {:get_application, application} when application != nil <-
               {:get_application, Action.Application.get_application_by_client_id(client_id)},
             {:validate_application, true} <-
               {:validate_application, authorization_code.application_id == application.id},
             {:validate_redirect_uri, true} <-
               {:validate_redirect_uri,
                Action.Application.validate_redirect_uri(application.id, redirect_uri)},
             {:get_or_create_grant_if_not_reused, {:ok, grant}} <-
               {
                 :get_or_create_grant_if_not_reused,
                 Action.Grant.get_or_create_grant_if_not_reused(
                   application.id,
                   authorization_code.guild_id,
                   code
                 )
               },
             _ <- Action.Grant.create_grant_scopes(grant.id, authorization_code.scopes),
             {:ok, access_token} <- Action.AccessToken.create_access_token(grant.id),
             {:ok, refresh_token} <- create_refresh_token_if_application_use(application, grant) do
          if refresh_token == nil do
            {
              :ok,
              %{
                access_token: access_token.token,
                token_type: "Bearer",
                expires_in: 3600,
                scopes: authorization_code.scopes
              }
            }
          else
            {
              :ok,
              %{
                access_token: access_token.token,
                token_type: "Bearer",
                expires_in: 3600,
                refresh_token: refresh_token.token,
                scopes: authorization_code.scopes
              }
            }
          end
        else
          {:code_expiration, _} ->
            {:error, {:invalid_grant, :invalid_code}}

          {:get_application, nil} ->
            {:error, {:invalid_request, :not_found_client}}

          {:validate_application, false} ->
            {:error, {:invalid_grant, :issued_to_other_client}}

          {:validate_redirect_uri, false} ->
            {:error, {:invalid_grant, :redirect_uri_mismatch}}

          {:get_or_create_grant_if_not_reused, {:error, :invalid_code}} ->
            {:commit, {:error, {:invalid_grant, :used_code}}}

          {:error, _} = err ->
            err
        end
    end
  end

  def token_refresh_token(refresh_token) do
    with {:ok, new_refresh_token} <- Action.RefreshToken.replace_refresh_token(refresh_token),
         {:ok, access_token} <- Action.AccessToken.create_access_token(new_refresh_token.grant_id) do
      {
        :ok,
        %{
          access_token: access_token.token,
          token_type: "Bearer",
          expires_in: 3600,
          refresh_token: new_refresh_token.token_id
        }
      }
    else
      {:error, :invalid_token} -> {:error, {:invalid_grant, :invalid_refresh_token}}
      {:error, :retry_limit} = err -> err
    end
  end

  def token_client_credentials(client_id, client_secret, discord_guild_id) do
    with {:ok, authorized_application} <-
           Action.Application.get_application_by_client_id_and_verify_secret(
             client_id,
             client_secret
           ),
         {:get_grant, grant} when grant != nil <-
           {:get_grant,
            Repo.get_by(Auth.Grant,
              application_id: authorized_application.id,
              guild_id: discord_guild_id
            )},
         {:ok, access_token} <- Action.AccessToken.create_access_token(grant.id) do
      if Enum.member?(authorized_application.grant_types, "refresh_token") do
        refresh_token =
          case Repo.get_by(Auth.RefreshToken, grant_id: grant.id) do
            nil ->
              case Action.RefreshToken.create_refresh_token(grant.id) do
                {:ok, token} -> token.token_id
                {:error, :retry_limit} -> raise "UNEXPECTED!"
              end

            old_refresh_token ->
              {:ok, new_refresh_token} =
                Action.RefreshToken.replace_refresh_token(old_refresh_token.token_id)

              new_refresh_token.token_id
          end

        {
          :ok,
          %{
            access_token: access_token.token,
            expires_in: DateTime.diff(access_token.expires, DateTime.utc_now()),
            token_type: "Bearer",
            refresh_token: refresh_token
          }
        }
      else
        {
          :ok,
          %{
            access_token: access_token.token,
            expires_in: DateTime.diff(access_token.expires, DateTime.utc_now()),
            token_type: "Bearer"
          }
        }
      end
    end
  end

  def revoke_refresh_token(refresh_token) do
    from(refresh_tokens in Auth.RefreshToken, where: refresh_tokens.token == ^refresh_token)
    |> Repo.delete_all()
  end

  def revoke_access_token(access_token) do
    from(access_tokens in Auth.AccessToken, where: access_tokens.token == ^access_token)
    |> Repo.delete_all()
  end

  def is_valid_access_token?(access_token) do
    q =
      from t in Auth.AccessToken,
        where: t.token == ^access_token

    Repo.exists?(q)
  end

  def is_valid_access_token?(access_token, guild_id) do
    q =
      from access_tokens in Auth.AccessToken,
        join: grants in Auth.Grant,
        on:
          access_tokens.token == ^access_token and grants.guild_id == ^guild_id and
            grants.id == access_tokens.grant_id

    Repo.exists?(q)
  end

  defp is_valid_scopes?(scopes) do
    scope_set = MapSet.new(scopes)
    MapSet.size(scope_set) == length(scopes) and MapSet.subset?(scope_set, MapSet.new(["openid"]))
  end

  def validate_authorization_request_and_get_application_info(
        scopes,
        redirect_uri,
        client_id
      ) do
    with {:get_application,
          %Auth.Application{
            id: application_id,
            client_name: client_name,
            grant_types: grant_types
          }} <-
           {:get_application, Action.Application.get_application_by_client_id(client_id)},
         {:validate_redirect_uri, true} <-
           {:validate_redirect_uri,
            Action.Application.validate_redirect_uri(application_id, redirect_uri)},
         {:validate_application_grant_type, true} <-
           {:validate_application_grant_type, grant_types |> Enum.member?("authorization_code")},
         {:validate_scopes, true} <- {:validate_scopes, is_valid_scopes?(scopes)} do
      {:ok, %{client_name: client_name}}
    else
      {:validate_scopes, false} ->
        {:error, {:invalid_request, :invalid_scope}}

      {:get_application, nil} ->
        {:error, :invalid_client_id}

      {:validate_application_grant_type, false} ->
        {:error, {:unauthorized_client, :invalid_application_grant_type}}

      {:validate_redirect_uri, false} ->
        {:error, :invalid_redirect_uri}
    end
  end
end
