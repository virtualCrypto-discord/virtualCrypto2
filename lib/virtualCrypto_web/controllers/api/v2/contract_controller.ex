defmodule VirtualCryptoWeb.Api.V2.ContractController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money
  alias VirtualCryptoWeb.Filtering.Discord, as: Filtering

  import VirtualCryptoWeb.Plug.DiscordApiService, only: [get_service: 1]

  defp get_discord_user(discord_user_id, service) do
    user = Discord.Api.Cached.get_user(discord_user_id, service)

    Filtering.user(user)
  end

  defp permission_denied(conn) do
    conn
    |> put_status(403)
    |> render(:error, %{error: :invalid_token, error_description: :permission_denied})
  end

  defp invalid_request(conn, desc) do
    conn
    |> put_status(400)
    |> render(:error, %{error: :invalid_request, error_description: desc})
  end

  defp format_contractor(contractor, service) do
    %{
      "user" => format_user(contractor.user, service),
      "deposits" => Enum.map(contractor.deposits, &format_deposit/1),
      "status" => contractor.status
    }
  end

  defp format_app(%{id: id}) do
    %{id: to_string(id)}
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
           contractors: contractors
         },
         service
       ) do
    %{
      "id" => contract.id |> to_string,
      "intermediate" => format_app(intermediate),
      "contractor" => contractors |> Enum.map(&format_contractor(&1, service)),
      "created_at" => DateTime.from_naive!(contract.inserted_at, "Etc/UTC"),
      "updated_at" => DateTime.from_naive!(contract.updated_at, "Etc/UTC")
    }
  end

  defp format_deposit(deposit) do
    %{
      "deposit_amount" => to_string(deposit.deposit_amount),
      "executed_amount" => to_string(deposit.executed_amount),
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

  defp create_contract(conn, intermediary_id, params) do
    if user = VirtualCrypto.User.get_user_by_id(intermediary_id) do
      case Money.create_contract(user.application_id, params) do
        {:ok, contract} ->
          conn
          |> put_status(201)
          |> render(:data, %{contract: format_contract(contract, get_service(conn))})

        {:error, error} ->
          conn
          |> invalid_request(error)
      end
    else
      conn
      |> put_status(400)
      |> render(:error, %{error: :invalid_request, error_description: :intermediary_not_found})
    end
  end

  defp convert_deposit(%{"currency_unit" => unit, "deposit_amount" => deposit_amount}) do
    {:ok,
     %{
       currency_unit: unit,
       deposit_amount: deposit_amount
     }}
  end

  defp convert_deposit(%{}) do
    {:error, :currency_unit_and_amount_is_required}
  end

  defp convert_deposits([], acc) do
    {:ok, acc}
  end

  defp convert_deposits([head | tail], acc) do
    case convert_deposit(head) do
      {:ok, head} -> convert_deposits(tail, [head | acc])
      {:error, error} -> {:error, error}
    end
  end

  defp convert_deposits(_, _acc) do
    {:error, :deposits_must_be_list}
  end

  defp convert_contractor(%{"discord_id" => discord_id, "deposits" => deposits})
       when is_list(deposits) do
    with {:ok, deposits} <- convert_deposits(deposits, []),
         {_, {discord_id, ""}} <- {:parse_discord_id, Integer.parse(discord_id)} do
      {:ok, %{discord_id: discord_id, deposits: deposits}}
    else
      {:error, error} -> {:error, error}
      {:parse_discord_id, _} -> {:error, :failed_to_parse_discord_id}
    end
  end

  defp convert_contractor(%{"deposits" => _deposits}) do
    {:error, :invalid_deposit_field_type}
  end

  defp convert_contractor(%{}) do
    {:error, :deposits_field_is_required}
  end

  defp convert_contractor(_) do
    {:error, :invalid_contractor_type}
  end

  defp convert_contractors([], acc) do
    {:ok, acc}
  end

  defp convert_contractors([head | tail], acc) do
    case convert_contractor(head) do
      {:ok, head} -> convert_contractors(tail, [head | acc])
      {:error, error} -> {:error, error}
    end
  end

  def create(conn, %{"contractors" => contractors})
      when is_list(contractors) and length(contractors) >= 1 do
    case convert_contractors(contractors, []) do
      {:ok, contractors} ->
        case Guardian.Plug.current_resource(conn) do
          %{"sub" => intermediary_id, "vc.contract" => true, "kind" => "app"} ->
            create_contract(conn, intermediary_id, %{
              contractors: contractors
            })

          _ ->
            conn |> permission_denied()
        end

      {:error, err} ->
        conn |> invalid_request(err)
    end
  end

  def create(conn, _) do
    conn
    |> invalid_request(:contractors_field_is_required)
  end

  def execute_beta1(conn, %{
        "id" => contract_id,
        "version" => "beta1",
        "action" => %{"op" => "close"}
      }) do
    case Integer.parse(contract_id) do
      {contract_id, ""} ->
        case Guardian.Plug.current_resource(conn) do
          %{"sub" => intermediary_id, "vc.contract" => true, "kind" => "app"} ->
            case Money.cancel_contract(intermediary_id, contract_id) do
              {:ok, _} ->
                conn |> send_resp(204, "")

              {:error, error} ->
                conn
                |> put_status(500)
                |> json(%{error: "inernal_server_error", error_description: to_string(error)})
            end

          _ ->
            conn |> permission_denied()
        end

      _ ->
        conn
        |> invalid_request(:contract_id_must_be_integer)
    end
  end

  def execute_beta1(conn, %{
        "id" => contract_id,
        "version" => "beta1",
        "action" => %{"op" => "commit", "transactions" => trs}
      })
      when is_list(trs) do
    case Guardian.Plug.current_resource(conn) do
      %{"sub" => intermediary_id, "vc.contract" => true, "kind" => "app"} ->
        raise "TODO: "

      _ ->
        conn |> permission_denied()
    end
  end

  def execute_beta1(conn, %{
        "id" => _contract_id,
        "version" => "beta1",
        "action" => %{"op" => "commit", "transactions" => _trs}
      }) do
    conn
    |> invalid_request(:transactions_must_be_list)
  end

  def execute_beta1(conn, %{
        "id" => _contract_id,
        "version" => "beta1",
        "action" => %{"op" => "commit"}
      }) do
    conn
    |> invalid_request(:missing_transactions)
  end

  def execute_beta1(conn, %{
        "id" => _contract_id,
        "version" => "beta1",
        "action" => %{"op" => _}
      }) do
    conn
    |> invalid_request(:invalid_action_op)
  end

  def execute_beta1(conn, %{
        "id" => _contract_id,
        "version" => "beta1",
        "action" => _
      }) do
    conn
    |> invalid_request(:missing_action_op)
  end

  def execute_beta1(
        conn,
        %{
          "id" => _contract_id,
          "version" => "beta1"
        } = params
      ) do
    conn
    |> invalid_request(:action_is_required)
  end

  def execute(conn, %{"version" => "beta1"} = params) do
    execute_beta1(conn, params)
  end

  def execute(conn, %{"version" => _}) do
    conn
    |> invalid_request(:invalid_version_field)
  end

  def execute(conn, _) do
    conn
    |> invalid_request(:version_is_required)
  end
end
