defmodule VirtualCryptoWeb.Api.V1V2.BalanceController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.VirtualCrypto, as: VCUser

  def balance(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        {:error}

      %{"sub" => user_id} ->
        balance_ = Money.balance(user: %VCUser{id: user_id})
        render(conn, "balance.json", params: %{data: balance_})
    end
  end
end
