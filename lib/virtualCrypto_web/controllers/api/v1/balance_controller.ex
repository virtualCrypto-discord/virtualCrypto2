defmodule VirtualCryptoWeb.Api.V1.BalanceController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money

  def balance(conn, _) do
    case Guardian.Plug.current_token(conn) do
      nil ->
        {:error}

      token ->
        {:ok, %{"sub" => user_id}} = VirtualCrypto.Guardian.decode_and_verify(token)
        balance_ = Money.balance(Money.VCService, user: user_id)

        render(conn, "balance.json",
          params: %{
            data:
              balance_
              |> Enum.map(fn %{amount: amount} = balance_ ->
                balance_ |> Map.put(:amount, amount)
              end)
          }
        )
    end
  end
end
