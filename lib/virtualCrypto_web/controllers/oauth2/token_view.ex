defmodule VirtualCryptoWeb.OAuth2.TokenView do
  def success(%{params: params}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end

  def error_code(%{params: {err, desc}}) do
    %{
      "error" => to_string(err),
      "error_description" => to_string(desc)
    }
  end

  def error_code(%{params: :invalid_client_id}) do
    %{
      "error" => "invalid_client"
    }
  end

  def error_code(%{params: v}) do
    %{
      "error" => "invalid_request",
      "error_description" => to_string(v)
    }
  end

  def error(%{params: :unsupported_grant_type}) do
    %{
      "error" => "unsupported_grant_type"
    }
  end

  def error(%{params: :grant_type_parameter_missing}) do
    %{
      "error" => "invalid_request",
      "error_description" => "grant_type_parameter_missing"
    }
  end

  def refresh(%{params: {:ok, params}}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end

  def refresh(%{params: {:error, {err, desc}}}) do
    %{
      "error" => to_string(err),
      "error_description" => to_string(desc)
    }
  end

  def refresh(%{params: {:error, v}}) do
    %{
      "error" => "invalid_request",
      "error_description" => to_string(v)
    }
  end

  def credentials(%{params: {:ok, params}}) do
    params |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
  end

  def credentials(%{params: {:error, v}}) do
    %{
      "error" => to_string(v)
    }
  end
end
