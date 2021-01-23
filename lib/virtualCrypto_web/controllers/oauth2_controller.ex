defmodule VirtualCryptoWeb.Oauth2Controller do
  use VirtualCryptoWeb, :controller
  use Bitwise
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Auth.Application.Metadata.Validater

  defp validate_executor(conn, guild) do
    guild_id = guild["id"]
    user_id = conn.private.plug_session["user"].id

    with {200, member} <-
           Discord.Api.V8.get_guild_member_with_status_code(
             guild_id,
             user_id
           ),
         roles <-
           Discord.Api.V8.roles(guild_id)
           |> Enum.map(fn %{"id" => id} = m -> {id, m} end)
           |> Map.new(),
         {:perms, true} <-
           {:perms,
            String.to_integer(guild["owner_id"]) == user_id ||
              Discord.Permissions.check(
                member["roles"]
                |> Enum.map(&String.to_integer(roles[&1]["permissions"]))
                |> Enum.reduce(0, &(&1 ||| &2)),
                Discord.Permissions.administrator()
              )} do
      :ok
    else
      {:perms, _} -> {:error, {:invalid_request, :permission_denied}}
      _ -> {:error, {:invalid_request, :invalid_guild_id}}
    end
  end

  def authorize(conn, %{"response_type" => "code"} = params) do
    props =
      with {:client_id, %{"client_id" => client_id}} <- {:client_id, params},
           {:redirect_uri, %{"redirect_uri" => redirect_uri}} <- {:redirect_uri, params},
           {:scope, scope} <- {:scope, Map.get(params, "scope", "")},
           {:ok, application_info} <-
             Auth.preauthorize(%{
               scopes: scope |> String.split(" "),
               redirect_uri: redirect_uri,
               client_id: client_id
             }),
           {:guild_id, %{"guild_id" => guild_id}} <- {:guild_id, params},
           {:guild_id, guild} <- {:guild_id, Discord.Api.V8.get_guild(guild_id)},
           {:guild_id, {200, _bot}} <-
             {:guild_id,
              Discord.Api.V8.get_guild_member_with_status_code(
                guild_id,
                Application.get_env(:virtualCrypto, :client_id)
              )},
           :ok <- validate_executor(conn, guild) do
        {:ok,
         {application_info,
          %{
            scope: scope,
            redirect_uri: redirect_uri,
            client_id: client_id,
            state: Map.get(params, "state"),
            response_type: "code",
            guild_id: guild_id
          }}}
      else
        {:client_id, _} -> {:error, :invalid_client_id}
        {:redirect_uri, _} -> {:error, :invalid_redirect_uri}
        {:scope, _} -> {:error, {:invalid_request, :invalid_scope}}
        {:guild_id, _} -> {:error, {:invalid_request, :invalid_guild_id}}
        v -> v
      end

    case props do
      {:ok, {app, session}} ->
        render(conn, "authorize.html", app: app, session: session)

      {:error, x} ->
        case x do
          err when err in [:invalid_client_id, :invalid_redirect_uri] ->
            render(conn, "error.authorize.html", error: :invalid_request, desc: err)

          {error, error_description} ->
            conn
            |> put_status(303)
            |> redirect(
              external:
                params["redirect_uri"]
                |> URI.parse()
                |> Map.put(
                  :query,
                  URI.encode_query(%{
                    error: error,
                    error_description: error_description
                  })
                )
                |> URI.to_string()
            )
        end
    end
  end

  def authorize(conn, _) do
    render(conn, "error.authorize.html", error: :invalid_request, desc: :invalid_response_type)
  end

  def authorize_action(conn, %{"response_type" => "code", "action" => "approve"} = params) do
    props =
      with {:client_id, %{"client_id" => client_id}} <- {:client_id, params},
           {:redirect_uri, %{"redirect_uri" => redirect_uri}} <- {:redirect_uri, params},
           {:scope, %{"scope" => scope}} <- {:scope, params},
           {:guild_id, %{"guild_id" => guild_id}} <- {:guild_id, params},
           {:guild_id, guild} <- {:guild_id, Discord.Api.V8.get_guild(guild_id)},
           {:guild_id, {200, _bot}} <-
             {:guild_id,
              Discord.Api.V8.get_guild_member_with_status_code(
                guild_id,
                Application.get_env(:virtualCrypto, :client_id)
              )},
           :ok <- validate_executor(conn, guild),
           {:ok, info} <-
             Auth.authorize(%{
               scopes: String.split(scope, " "),
               redirect_uri: redirect_uri,
               client_id: client_id,
               guild_id: String.to_integer(guild_id)
             }) do
        {:ok, %{redirect_uri: redirect_uri, code: info.code, scope: scope, guild_id: guild_id}}
      else
        {:client_id, _} -> {:error, :invalid_client_id}
        {:redirect_uri, _} -> {:error, :invalid_redirect_uri}
        {:scope, _} -> {:error, :invalid_scope}
        {:guild_id, _} -> {:error, :invalid_guild_id}
      end

    case props do
      {:ok, %{redirect_uri: redirect_uri, code: code, scope: scope, guild_id: guild_id}} ->
        q =
          Map.merge(
            %{code: code, guild_id: guild_id, scope: scope},
            case Map.get(params, "state") do
              nil -> %{}
              state -> %{state: state}
            end
          )

        conn
        |> put_status(303)
        |> redirect(
          external:
            redirect_uri |> URI.parse() |> Map.put(:query, URI.encode_query(q)) |> URI.to_string()
        )

      {:error, x} ->
        case x do
          err when err in [:invalid_client_id, :invalid_redirect_uri] ->
            render(conn, "authorize.html", error: err)
        end
    end
  end

  def token(conn, %{"grant_type" => "authorization_code"} = params) do
    params =
      with {:client_id, %{"client_id" => client_id}} <- {:client_id, params},
           {:redirect_uri, %{"redirect_uri" => redirect_uri}} <- {:redirect_uri, params},
           {:code, %{"code" => code}} <- {:code, params} do
        Auth.exchange_token_by_authroization_code(%{
          client_id: client_id,
          redirect_uri: redirect_uri,
          code: code
        })
      else
        {:client_id, _} -> {:error, {:invalid_request, :client_id}}
        {:redirect_uri, _} -> {:error, {:invalid_request, :redirect_uri}}
        {:code, _} -> {:error, {:invalid_request, :code}}
      end

    case params do
      {:ok, params} -> render(conn, "success.code.token.json", params: params)
      {:error, params} -> render(conn, "error.code.token.json", params: params)
    end
  end

  def token(conn, %{"grant_type" => "refresh_token"} = params) do
    params =
      with {:token, %{"refresh_token" => token}} <- {:token, params} do
        Auth.exchange_token_by_refresh_token(%{token: token})
      else
        {:token, _} -> {:error, {:invalid_request, :refresh_token}}
      end

    case params do
      {:ok, _} ->
        render(conn, "refresh.token.json", params: params)

      {:error, _} ->
        conn
        |> put_status(400)
        |> render(conn, "refresh.token.json", params: params)
    end
  end

  def token(conn, %{"grant_type" => "client_credentials"} = params) do
    params =
      with {:validate_credentials, {client_id, client_secret}} <-
             {:validate_credentials, Plug.BasicAuth.parse_basic_auth(conn)},
           {:guild_id, %{"guild_id" => guild_id}} = {:guild_id, params} do
        Auth.exchange_token_by_client_credentials(%{
          client_id: client_id,
          client_secret: client_secret,
          guild_id: guild_id
        })
      else
        {:validate_credentials, _} -> {:error, :invalid_client}
        {:guild_id, _} -> {:error, :invalid_request}
      end

    case params do
      {:ok, _} ->
        render(conn, "credentials.token.json", params: params)

      {:error, _} ->
        conn
        |> put_status(400)
        |> render("credentials.token.json", params: params)
    end
  end

  def token(conn, %{"grant_type" => _}) do
    conn
    |> put_status(400)
    |> render("error.token.json", params: :unsupported_grant_type)
  end

  def token(conn, _) do
    conn
    |> put_status(400)
    |> render("error.token.json", params: :grant_type_parameter_missing)
  end

  defp fetch(m, k, e) do
    case Map.fetch(m, k) do
      :error -> {:error, e}
      {:ok, v} -> v
    end
  end

  defp get_and_compute(req) do
    fn km, validater ->
      case Map.fetch(req, to_string(km)) do
        {:ok, v} ->
          case validater.(v) do
            {:ok, v} -> %{km => v}
            {:error, _} = err -> err
          end

        :error ->
          %{}
      end
    end
  end

  def clients_get(conn, %{"user" => "@me"}) do
    with {{:validate_token, :token_verification_failed},
          %{"sub" => user_id, "oauth2.register" => true, "kind" => "user"}} <-
           {{:validate_token, :token_verification_failed}, Guardian.Plug.current_resource(conn)} do
      conn |> render("clients.register.json", applications: Auth.get_user_application(user_id))
    else
      {{:validate_token, more}, _} ->
        conn
        |> put_status(400)
        |> render("error.register.json",
          error: :invalid_token,
          error_description: more
        )
    end
  end

  def clients_get(conn, _) do
    conn
    |> put_status(400)
    |> render("error.register.json",
      error: :invalid_request,
      error_description: :required_user_parameter
    )
  end

  def clients_post(conn, req) do
    f = get_and_compute(req)

    params =
      with {{:validate_token, :token_verification_failed},
            %{"sub" => user_id, "oauth2.register" => true, "kind" => "user"}} <-
             {{:validate_token, :token_verification_failed}, Guardian.Plug.current_resource(conn)},
           {{:validate_token, :invalid_user},
            %VirtualCrypto.User.User{discord_id: owner_discord_id}} <-
             {{:validate_token, :invalid_user}, VirtualCrypto.User.get_user_by_id(user_id)},
           {{:validate_token, :getting_discord_access_token_failed_while_user_verification},
            %VirtualCrypto.DiscordAuth.DiscordUser{token: discord_access_token}} <-
             {{:validate_token, :getting_discord_access_token_failed_while_user_verification},
              VirtualCrypto.DiscordAuth.refresh_user(owner_discord_id)},
           {{:validate_token, :user_verification_failed}, false} <-
             {{:validate_token, :user_verification_failed},
              Map.get(Discord.Api.V8.OAuth2.get_user_info(discord_access_token), "bot", false)},
           %{} = response_types <- f.(:response_types, &Validater.validate_response_types/1),
           %{} = grant_types <- f.(:grant_types, &Validater.validate_grant_types/1),
           %{} = application_type <-
             f.(:application_type, &Validater.validate_application_type/1),
           %{} = client_name <- f.(:client_name, &{:ok, &1}),
           %{} = client_uri <- f.(:client_uri, &Validater.validate_client_uri/1),
           %{} = logo_uri <- f.(:logo_uri, &Validater.validate_logo_uri/1),
           %{} = discord_support_server_invite_slug <-
             f.(
               :discord_support_server_invite_slug,
               &Validater.validate_discord_support_server_invite_slug/1
             ),
           redirect_uris when is_list(redirect_uris) <-
             fetch(req, "redirect_uris", {:invalid_redirect_uri, :redirect_uris_must_be_array}),
           {:validate_redirect_uris, true} <-
             {:validate_redirect_uris,
              redirect_uris |> Enum.all?(&(URI.parse(&1).scheme in ["http", "https"]))} do
        Auth.register_application(
          %{
            redirect_uris: redirect_uris,
            owner_discord_id: owner_discord_id
          }
          |> Map.merge(response_types)
          |> Map.merge(application_type)
          |> Map.merge(client_name)
          |> Map.merge(grant_types)
          |> Map.merge(client_uri)
          |> Map.merge(logo_uri)
          |> Map.merge(discord_support_server_invite_slug)
        )
      else
        {{:validate_token, more}, _} ->
          {:error, {:invalid_token, more}}

        {:validate_redirect_uris, _} ->
          {:error, {:invalid_redirect_uri, :redirect_uri_scheme_must_be_http_or_https}}

        err ->
          err
      end

    case params do
      {:ok, application_data} ->
        {:ok, access_token, _} =
          VirtualCrypto.Guardian.issue_token_for_app_user(application_data.user.id, [
            "oauth2.register"
          ])

        render(conn, "ok.register.json",
          application: application_data.application,
          registration_access_token: access_token,
          registration_client_uri:
            Application.get_env(:virtualCrypto, :site_url)
            |> URI.parse()
            |> Map.put(:path, "/oauth2/register")
            |> URI.to_string()
        )

      {:error, {:invalid_token, more}} ->
        conn
        |> put_resp_header(
          "WWW-Authenticate",
          [
            "Bearer realm=\"oauth2.register\"",
            "errror=\"invalid_token\"",
            ~s/error_description="#{more}"/
          ]
          |> Enum.join(",")
        )
        |> send_resp(401, "\"Unauthorized\"")
        |> halt()

      {:error, {error, error_description}} ->
        conn
        |> put_status(400)
        |> render("error.register.json", error: error, error_description: error_description)
    end
  end

  def clients_me_get(conn, _params) do
    params =
      with {{:validate_token, :token_verification_failed},
            %{"sub" => user_id, "oauth2.register" => true, "kind" => "app.user"}} <-
             {{:validate_token, :token_verification_failed}, Guardian.Plug.current_resource(conn)},
           {{:validate_token, :invalid_user},
            %VirtualCrypto.User.User{application_id: application_id} = user} <-
             {{:validate_token, :invalid_user}, VirtualCrypto.User.get_user_by_id(user_id)} do
        case VirtualCrypto.Auth.get_application(application_id) do
          nil -> {:error, {:invalid_token, :invalid_user}}
          data -> {:ok, data |> Map.put(:user, user)}
        end
      else
        {{:validate_token, more}, _} ->
          {:error, {:invalid_token, more}}
      end

    case params do
      {:ok, %{application: application, redirect_uris: redirect_uris, user: user}} ->
        render(conn, "info.register.json",
          application: application,
          redirect_uris: redirect_uris,
          user: user
        )

      {:error, {:invalid_token, more}} ->
        conn
        |> put_resp_header(
          "WWW-Authenticate",
          [
            "Bearer realm=\"oauth2.register\"",
            "errror=\"invalid_token\"",
            ~s/error_description="#{more}"/
          ]
          |> Enum.join(",")
        )
        |> send_resp(401, "\"Unauthorized\"")
        |> halt()

      {:error, {error, error_description}} ->
        conn
        |> put_status(400)
        |> render("error.register.json", error: error, error_description: error_description)
    end
  end

  def clients_me_patch(conn, params) do
    params =
      with {{:validate_token, :token_verification_failed},
            %{"sub" => user_id, "oauth2.register" => true, "kind" => "app.user"}} <-
             {{:validate_token, :token_verification_failed}, Guardian.Plug.current_resource(conn)},
           {{:validate_token, :invalid_user},
            %VirtualCrypto.User.User{application_id: application_id}} <-
             {{:validate_token, :invalid_user}, VirtualCrypto.User.get_user_by_id(user_id)} do
        VirtualCrypto.Auth.Application.PatchQuery.patch(application_id, params)
      end

    case params do
      {:ok, _} ->
        conn |> send_resp(204, "")

      {:error, {error, error_description}} ->
        conn
        |> put_status(400)
        |> render("error.register.json", error: error, error_description: error_description)
    end
  end
end
