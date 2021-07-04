defmodule VirtualCryptoWeb.Api.V2.CurrenciesController do
  @moduledoc """
   renamed from InfoController
  """
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money

  defp get(%{"id" => id}) do
    case Integer.parse(id) do
      {int_id, ""} when int_id >= 1 -> {:ok, {:id, int_id}}
      _ -> {:error, {:invalid_request, :id_must_be_positive_integer}}
    end
  end

  defp get(%{"guild" => guild_id}) do
    case Integer.parse(guild_id) do
      {int_guild_id, ""} when int_guild_id >= 1 -> {:ok, {:guild, int_guild_id}}
      _ -> {:error, {:invalid_request, :guild_id_must_be_positive_integer}}
    end
  end

  defp get(%{"name" => name}) do
    {:ok, {:name, name}}
  end

  defp get(%{"unit" => unit}) do
    {:ok, {:unit, unit}}
  end

  defp response_code(conn, :invalid_request) do
    conn |> put_status(400)
  end

  defp response_code(conn, :not_found) do
    conn |> put_status(404)
  end

  def index(conn, params) do
    m = Map.take(params, ["id", "guild", "name", "unit"])

    params =
      case map_size(m) do
        1 ->
          with {:ok, req} <- get(m),
               {:info, %{} = res} <- {:info, Money.info([req])} do
            {:ok, res}
          else
            {:info, nil} ->
              {:error, {:not_found, :not_found}}

            x ->
              x
          end

        _ ->
          {:error, {:invalid_request, :need_one_parameter_from_id_guild_name_or_unit}}
      end

    case params do
      {:ok, res} ->
        render(conn, "ok.json", params: res)

      {:error, {error, error_description}} ->
        conn
        |> response_code(error)
        |> render("error.json", error: error, error_description: error_description)
    end
  end
end
