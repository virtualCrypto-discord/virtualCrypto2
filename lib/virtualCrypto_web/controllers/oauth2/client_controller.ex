defmodule VirtualCryptoWeb.OAuth2.ClientController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Auth
  alias VirtualCrypto.User

  def get(conn, _params) do
    params =
      with {{:validate_token, :token_verification_failed},
            %{"sub" => user_id, "oauth2.register" => true, "kind" => "app.user"}} <-
             {{:validate_token, :token_verification_failed}, Guardian.Plug.current_resource(conn)},
           {{:validate_token, :invalid_user}, %User.User{application_id: application_id} = user} <-
             {{:validate_token, :invalid_user}, User.get_user_by_id(user_id)} do
        case Auth.get_application(application_id) do
          nil -> {:error, {:invalid_token, :invalid_user}}
          data -> {:ok, data |> Map.put(:user, user)}
        end
      else
        {{:validate_token, more}, _} ->
          {:error, {:invalid_token, more}}
      end

    case params do
      {:ok, %{application: application, redirect_uris: redirect_uris, user: user}} ->
        render(conn, "client.register.json",
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

  def patch(conn, params) do
    params =
      with {{:validate_token, :token_verification_failed},
            %{"sub" => user_id, "oauth2.register" => true, "kind" => "app.user"}} <-
             {{:validate_token, :token_verification_failed}, Guardian.Plug.current_resource(conn)},
           {{:validate_token, :invalid_user}, %User.User{application_id: application_id}} <-
             {{:validate_token, :invalid_user}, User.get_user_by_id(user_id)} do
        Auth.Application.PatchQuery.patch(application_id, params)
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
