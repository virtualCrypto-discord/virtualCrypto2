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
                VirtualCryptoWeb.Clients.render_application(%{
                  application: application,
                  redirect_uris: redirect_uris,
                  user: app_user
                })
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
