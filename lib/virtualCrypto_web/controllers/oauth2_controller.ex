defmodule VirtualCryptoWeb.Oauth2Controller do
  use VirtualCryptoWeb, :controller
  use Bitwise

  alias VirtualCrypto.OAuth2

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
             OAuth2.preauthorize(%{
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
             OAuth2.authorize(%{
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
        OAuth2.exchange_token_by_authroization_code(%{
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
        OAuth2.exchange_token_by_refresh_token(%{token: token})
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
        OAuth2.exchange_token_by_client_credentials(%{
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
end
