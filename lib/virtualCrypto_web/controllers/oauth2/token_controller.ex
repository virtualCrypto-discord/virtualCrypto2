defmodule VirtualCryptoWeb.OAuth2.TokenController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Auth

  def post(conn, %{"grant_type" => "authorization_code"} = params) do
    params =
      with {:client_id, %{"client_id" => client_id}} <- {:client_id, params},
           {:redirect_uri, %{"redirect_uri" => redirect_uri}} <- {:redirect_uri, params},
           {:code, %{"code" => code}} <- {:code, params} do
        Auth.exchange_token_by_authorization_code(%{
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

  def post(conn, %{"grant_type" => "refresh_token"} = params) do
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
        |> render("refresh.token.json", params: params)
    end
  end

  def post(conn, %{"grant_type" => "client_credentials", "guild_id" => guild_id}) do
    params =
      with {:validate_credentials, {client_id, client_secret}} <-
             {:validate_credentials, Plug.BasicAuth.parse_basic_auth(conn)} do
        Auth.exchange_token_by_client_credentials(%{
          client_id: client_id,
          client_secret: client_secret,
          guild_id: guild_id
        })
      else
        {:validate_credentials, _} -> {:error, :invalid_client}
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

  def post(conn, %{"grant_type" => "client_credentials", "scope" => scope}) do
    allowed_scope_set = MapSet.new(["vc.pay", "vc.claim", "oauth2.register"])

    params =
      with {:validate_credentials, {client_id, client_secret}} <-
             {:validate_credentials, Plug.BasicAuth.parse_basic_auth(conn)},
           {:validate_credentials, id} when id != nil <-
             {:validate_credentials,
              Auth.get_application_user_id_by_client_id(
                client_id,
                client_secret
              )},
           scopes <- String.split(scope, " "),
           scope_set <- MapSet.new(scopes),
           {:validate_scopes, true} <-
             {:validate_scopes, MapSet.size(scope_set) == length(scopes)},
           {:validate_scopes, true} <-
             {:validate_scopes, MapSet.subset?(scope_set, allowed_scope_set)} do
        {:ok, access_token, %{"exp" => expires}} =
          VirtualCrypto.Guardian.issue_token_for_app(
            id,
            scopes
          )

        {:ok,
         %{
           access_token: access_token,
           expires_in: DateTime.diff(DateTime.from_unix!(expires), DateTime.utc_now()),
           token_type: "Bearer"
         }}
      else
        {:validate_credentials, _} -> {:error, :invalid_client}
        {:validate_scopes, _} -> {:error, :invalid_request}
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

  def post(conn, %{"grant_type" => _}) do
    conn
    |> put_status(400)
    |> render("error.token.json", params: :unsupported_grant_type)
  end

  def post(conn, _) do
    conn
    |> put_status(400)
    |> render("error.token.json", params: :grant_type_parameter_missing)
  end
end
