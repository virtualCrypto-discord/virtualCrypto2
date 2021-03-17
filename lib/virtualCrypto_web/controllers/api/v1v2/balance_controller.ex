defmodule VirtualCryptoWeb.Api.V1V2.BalanceController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money

  def balance(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        {:error}

      %{"sub" => user_id} ->
        balance_ = Money.balance(Money.VCService, user: user_id)
        render(conn, "balance.json", params: %{data: balance_})
    end
  end
end
