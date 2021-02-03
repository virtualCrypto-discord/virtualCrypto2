defmodule VirtualCryptoWeb.OAuth2.ClientView do
  use VirtualCryptoWeb, :view

  def render("client.register.json", %{
        application: application,
        redirect_uris: redirect_uris,
        user: user
      }) do
    VirtualCryptoWeb.Clients.render_application(%{
      application: application,
      user: user,
      redirect_uris: redirect_uris
    })
  end

  def render("error.register.json", %{error: error, error_description: error_description}) do
    %{
      "error" => to_string(error),
      "error_description" => to_string(error_description)
    }
  end
end
