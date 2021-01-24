defmodule VirtualCryptoWeb.Clients do
  def render_application(%{
        application: application,
        redirect_uris: redirect_uris,
        user: user
      }) do
    %{
      "client_id" => application.client_id,
      "client_secret" => application.client_secret,
      "redirect_uris" => redirect_uris |> Enum.map(& &1.redirect_uri),
      "user_id" => user.id,
      "discord_user_id" =>
        unless user.discord_id == nil do
          to_string(user.discord_id)
        else
          nil
        end,
      "application_type" => application.application_type,
      "client_name" => application.client_name,
      "client_uri" => application.client_uri,
      "discord_support_server_invite_slug" => application.discord_support_server_invite_slug,
      "grant_types" => application.grant_types,
      "logo_uri" => application.logo_uri,
      "owner_discord_id" => to_string(application.owner_discord_id),
      "response_types" => application.response_types
    }
  end
end
