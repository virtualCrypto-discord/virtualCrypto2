defmodule VirtualCryptoWeb.Api.V1.BalanceView do
  use VirtualCryptoWeb, :view

  def render("balance.json", %{params: %{data: data}}) do
    data
    |> Enum.map(fn %{asset: asset, currency: currency} ->
      %{
        "amount" => to_string(asset.amount),
        "currency" => %{
          "name" => currency.name,
          "unit" => currency.unit,
          "guild" => to_string(currency.guild_id),
          "pool_amount" => to_string(currency.pool_amount)
        }
      }
    end)
  end
end
