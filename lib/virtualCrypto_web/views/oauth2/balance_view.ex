defmodule VirtualCryptoWeb.V1.BalanceView do
  use VirtualCryptoWeb, :view

  def render("balance.json", %{params: %{data: data}}) do
    data
  end
end
