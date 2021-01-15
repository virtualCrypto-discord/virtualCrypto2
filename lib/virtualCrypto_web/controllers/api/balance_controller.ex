defmodule VirtualCryptoWeb.V1.BalanceController do
  use VirtualCryptoWeb, :controller
  import Plug.Conn, only: [get_session: 2]

  def balance(conn, _) do
    user = get_session(conn, :user)
    balance_ = VirtualCrypto.Money.balance(user: user.id)
    render( conn, "balance.json", params: %{data: balance_})
  end
end
