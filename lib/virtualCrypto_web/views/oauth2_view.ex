defmodule VirtualCryptoWeb.Oauth2View do
  use VirtualCryptoWeb, :view
  import Phoenix.Controller, only: [get_csrf_token: 0]

  def render("success.code.token.json", %{params: params}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end

  def render("error.code.token.json", %{params: {err, desc}}) do
    %{
      "error" => to_string(err),
      "error_description" => to_string(desc)
    }
  end

  def render("error.code.token.json", %{params: :invalid_client_id}) do
    %{
      "error" => "invalid_client"
    }
  end

  def render("error.code.token.json", %{params: v}) do
    %{
      "error" => "invalid_request",
      "error_description" => to_string(v)
    }
  end

  def render("error.token.json", %{params: :unsupported_grant_type}) do
    %{
      "error" => "unsupported_grant_type"
    }
  end

  def render("error.token.json", %{params: :grant_type_parameter_missing}) do
    %{
      "error" => "invalid_request",
      "error_description" => "grant_type_parameter_missing"
    }
  end

  def render("refresh.token.json", %{params: {:ok, params}}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end

  def render("refresh.token.json", %{params: {:error, {err, desc}}}) do
    %{
      "error" => to_string(err),
      "error_description" => to_string(desc)
    }
  end

  def render("refresh.token.json", %{params: {:error, v}}) do
    %{
      "error" => "invalid_request",
      "error_description" => to_string(v)
    }
  end

  def render("credentials.token.json", %{params: {:ok, params}}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end

  def render("credentials.token.json", %{params: {:error, v}}) do
    %{
      "error" => to_string(v)
    }
  end

  def render("ok.register.json", %{
        application: application,
        registration_access_token: registration_access_token,
        registration_client_uri: registration_client_uri
      }) do
    %{
      "client_id" => application.client_id,
      "client_secret" => application.client_secret,
      "registration_access_token" => registration_access_token,
      "registration_client_uri" => registration_client_uri
    }
  end

  def render("error.register.json", %{error: error, error_description: error_description}) do
    %{
      "error" => to_string(error),
      "error_description" => to_string(error_description)
    }
  end

  def render("info.register.json", %{
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

  def render("clients.register.json", %{applications: applications}) do
    Enum.group_by(applications, fn {application, _, _} -> application.id end)
    |> Enum.map(fn {_application_id, [{application, user, _redirect_uri} | _tail] = list} ->
      render("info.register.json", %{
        application: application,
        user: user,
        redirect_uris: list |> Enum.map(&elem(&1, 2)) |> Enum.filter(&(&1 != nil))
      })
    end)
  end
end
