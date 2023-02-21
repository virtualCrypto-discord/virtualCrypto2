defmodule VirtualCryptoWeb.OAuth2.ClientsController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Auth
  alias VirtualCrypto.User
  alias VirtualCrypto.DiscordAuth

  def get(conn, %{"user" => "@me"}) do
    with cr <- Guardian.Plug.current_resource(conn),
         {{:validate_token, :invalid_token}, %{"sub" => user_id, "kind" => "user"}} <-
           {{:validate_token, :invalid_token}, cr},
         {{:validate_token, :insufficient_scope}, %{"oauth2.register" => true}} <-
           {{:validate_token, :insufficient_scope}, cr} do
      conn |> render("clients.register.json", applications: Auth.get_user_applications(user_id))
    else
      {{:validate_token, :invalid_token}, _} ->
        conn
        |> put_status(401)
        |> render("error.register.json",
          error: :invalid_token,
          error_description: :invalid_kind
        )

      {{:validate_token, :insufficient_scope}, _} ->
        conn
        |> put_status(403)
        |> render("error.register.json",
          error: :insufficient_scope,
          error_description: :required_oauth2_register
        )
    end
  end

  def get(conn, _) do
    conn
    |> put_status(400)
    |> render("error.register.json",
      error: :invalid_request,
      error_description: :required_user_parameter
    )
  end

  def post(conn, req) do
    params =
      with cr <- Guardian.Plug.current_resource(conn),
           {{:validate_token, :token_verification_failed}, %{"sub" => user_id, "kind" => "user"}} <-
             {{:validate_token, :token_verification_failed}, cr},
           {{:validate_scope, :required_oauth2_register_scope}, %{"oauth2.register" => true}} <-
             {{:validate_scope, :required_oauth2_register_scope}, cr},
           {{:validate_token, :invalid_user}, %User.User{discord_id: owner_discord_id}} <-
             {{:validate_token, :invalid_user}, User.get_user_by_id(user_id)},
           {{:validate_token, :getting_discord_access_token_failed_while_user_verification},
            %DiscordAuth.DiscordUser{token: discord_access_token}} <-
             {{:validate_token, :getting_discord_access_token_failed_while_user_verification},
              DiscordAuth.refresh_user(owner_discord_id)},
           {{:validate_token, :user_verification_failed}, false} <-
             {{:validate_token, :user_verification_failed},
              Map.get(Discord.Api.OAuth2.get_user_info(discord_access_token), "bot", false)} do
        Auth.register_application(
          user_id,
          %{
            owner_discord_id: owner_discord_id
          }
          |> Map.merge(req)
        )
      else
        {{:validate_token, more}, _} ->
          {:error, {:invalid_token, more}}

        {{:validate_scope, more}, _} ->
          {:error, {:insufficient_scope, more}}

        {:validate_redirect_uris, _} ->
          {:error, {:invalid_redirect_uri, :redirect_uri_scheme_must_be_http_or_https}}

        {:verify_webhook_url, {:err, x}} ->
          {:error, {:webhook_verification_failed, x}}

        err ->
          err
      end

    case params do
      {:ok, application_data} ->
        {:ok, access_token, _} =
          VirtualCrypto.Guardian.issue_token_for_app(application_data.user.id, [
            "oauth2.register"
          ])

        conn
        |> put_status(201)
        |> render("ok.register.json",
          application: application_data.application,
          registration_access_token: access_token,
          registration_client_uri:
            Application.get_env(:virtualCrypto, :site_url)
            |> URI.parse()
            |> Map.put(:path, "/oauth2/clients/@me")
            |> URI.to_string()
        )

      {:error, {:invalid_token, more}} ->
        conn
        |> put_status(401)
        |> render("error.register.json", error: :invalid_token, error_description: more)

      {:error, {:insufficient_scope, more}} ->
        conn
        |> put_status(403)
        |> render("error.register.json", error: :insufficient_scope, error_description: more)

      {:error, {error, error_description}} ->
        conn
        |> put_status(400)
        |> render("error.register.json", error: error, error_description: error_description)
    end
  end
end
