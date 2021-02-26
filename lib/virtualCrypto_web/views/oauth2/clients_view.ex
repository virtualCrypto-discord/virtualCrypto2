defmodule VirtualCryptoWeb.OAuth2.ClientsView do
  use VirtualCryptoWeb, :view

  def render("ok.register.json", %{
        application: application,
        registration_access_token: registration_access_token,
        registration_client_uri: registration_client_uri
      }) do
    %{
      "client_id" => application.client_id,
      "client_secret" => application.client_secret,
      "registration_access_token" => registration_access_token,
      "registration_client_uri" => registration_client_uri,
      "client_secret_expires_at" => 0,
    }
  end

  def render("error.register.json", %{error: error, error_description: error_description}) do
    %{
      "error" => to_string(error),
      "error_description" => to_string(error_description)
    }
  end

  def render("clients.register.json", %{applications: applications}) do
    Enum.group_by(applications, fn {application, _, _} -> application.id end)
    |> Enum.map(fn {_application_id, [{application, user, _redirect_uri} | _tail] = list} ->
      VirtualCryptoWeb.Clients.render_application(%{
        application: application,
        user: user,
        redirect_uris: list |> Enum.map(&elem(&1, 2)) |> Enum.filter(&(&1 != nil))
      })
    end)
  end
end
