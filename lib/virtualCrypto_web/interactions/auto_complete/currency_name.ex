defmodule VirtualCryptoWeb.Interaction.AutoComplete.CurrencyName do
  defp format(currencies) do
    currencies
    |> Enum.map(fn
      %{currency: %{name: name, unit: unit}, amount: amount} ->
        %{
          name: "通貨名: #{name} 所持量: #{amount}#{unit}",
          value: name
        }
    end)
  end

  defp list_candidates(name, nil, user) do
    case String.length(name) do
      0 ->
        VirtualCrypto.Money.search_currencies_with_asset_by_guild_and_user(
          nil,
          user
        )

      _ ->
        VirtualCrypto.Money.search_currencies_with_asset_by_name(name, nil, user)
    end
  end

  defp list_candidates(name, guild_id, user) do
    case String.length(name) do
      0 ->
        VirtualCrypto.Money.search_currencies_with_asset_by_guild_and_user(
          String.to_integer(guild_id),
          user
        )

      _ ->
        VirtualCrypto.Money.search_currencies_with_asset_by_name(
          name,
          String.to_integer(guild_id),
          user
        )
    end
  end

  def handle(name, guild_id, user) do
    list_candidates(name, guild_id, user) |> format
  end
end
