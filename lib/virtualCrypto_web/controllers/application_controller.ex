defmodule VirtualCryptoWeb.ApplicationController do
  alias VirtualCrypto.Auth
  use VirtualCryptoWeb, :controller

  def index(conn, %{"id" => id}) do
    user = get_session(conn, :user)

    case UUID.info(id) do
      {:ok, _} ->
        app = Auth.get_user_application(user.id, id)

        case app do
          nil ->
            conn |> resp(404, "Not found") |> send_resp() |> halt()

          app ->
            {application, app_user, redirect_uris} = app

            conn
            |> render("index.html",
              data:
                %{
                  "client_id" => application.client_id,
                  "client_secret" => application.client_secret,
                  "redirect_uris" => redirect_uris |> Enum.map(& &1.redirect_uri),
                  "discord_user_id" =>
                    unless app_user.discord_id == nil do
                      to_string(app_user.discord_id)
                    else
                      nil
                    end,
                  "application_type" => application.application_type,
                  "client_name" => application.client_name,
                  "client_uri" => application.client_uri,
                  "discord_support_server_invite_slug" =>
                    application.discord_support_server_invite_slug,
                  "grant_types" => application.grant_types,
                  "logo_uri" => application.logo_uri
                }
                |> Jason.encode!()
            )
        end

      {:error, _} ->
        conn |> resp(404, "Not found") |> send_resp() |> halt()
    end
  end

  def readme(conn, _params) do
    conn |> render("readme.html")
  end
end
