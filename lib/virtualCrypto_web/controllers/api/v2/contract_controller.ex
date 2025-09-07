defmodule VirtualCryptoWeb.Api.V2.ContractController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money
  import VirtualCryptoWeb.Plug.DiscordApiService, only: [get_service: 1]

  defp permission_denied(conn) do
    conn
    |> put_status(403)
    |> render(:error, %{error: :invalid_token, error_description: :permission_denied})
  end
  defp format_contractor(contractor,service) do
    %{
      "user" => format_user(contractor.user, service),
      "deposits" => Enum.map(contractor.deposit_agreements, &format_deposit/1)
    }
  end
  defp format_user(user, service) do
    %{
      "id" => to_string(user.id),
      "discord" =>
        if user.discord_id != nil do
          get_discord_user(user.discord_id, service)
        else
          nil
        end
    }
  end
  defp format_contract(
         %{
            contract: contract,
            intermediate: intermediate,
            contractor: contractor,
         },
         service
       ) do
    %{
      "id" => contract.id |> to_string,
      "intermediate" => format_user(intermediate,service),
      "contractor" => contractor|>Enum.map(&format_contractor(&1,service)),
      "created_at" => DateTime.from_naive!(contract.inserted_at, "Etc/UTC"),
      "updated_at" => DateTime.from_naive!(contract.updated_at, "Etc/UTC"),
    }
  end

  defp format_deposit(deposit) do
    %{
      "deposit_amount" => to_string(deposit.deposit_amount),
      "executed_amount" => to_string(deposit.executed_amount),
      "status" => deposit.status,
      "currency" => format_currency(deposit.currency)
    }
  end

  defp format_currency(currency) do
    %{
      "name" => currency.name,
      "unit" => currency.unit,
      "guild" => to_string(currency.guild_id),
      "pool_amount" => to_string(currency.pool_amount)
    }
  end

  defp create_contract(intermediary_id,params) do
    case Money.create_contract(intermediary_id,params) do
      {:ok,contract} ->
        conn
        |> put_status(201)
        |> render(:data, %{params: format_contract(contract, get_service(conn))})
      {:error,error} ->
    end
  end
  def post(conn,params) do
    case Guardian.Plug.current_resource(conn) do
      %{"sub" => intermediary_id, "vc.contract" => true} -> create_contract(intermediary_id, params)
      %{"sub" => _, "vc.contract" => false} ->
        conn |> permission_denied()
    end
  end
end
