defmodule VirtualCryptoWeb.Oauth2View do
  use VirtualCryptoWeb, :view
  import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

  def render("success.code.token.json", %{params: params}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end

  def render("error.code.token.json", %{params: {err,desc}}) do
    %{
      "error" => to_string(err),
      "error_description" =>  to_string(desc)
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
  def render("refresh.token.json", %{params: {:ok,params}}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end
  def render("refresh.token.json", %{params: {:error,{err,desc}}}) do
    %{
      "error" => to_string(err),
      "error_description" =>  to_string(desc)
    }
  end
  def render("refresh.token.json", %{params: {:error,v}}) do
    %{
      "error" => "invalid_request",
      "error_description" => to_string(v)
    }
  end
  def render("credentials.token.json", %{params: {:ok,params}}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end
  def render("credentials.token.json",%{params: {:error,v}}) do
    %{
      "error" => to_string(v)
    }
  end
end
