defmodule VirtualCryptoWeb.Interaction.AutoComplete do
  import VirtualCryptoWeb.Interaction.Util, only: [get_user: 1]
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser

  defp format_currencies_for_unit(currencies) do
    currencies
    |> Enum.map(fn
      %{currency: %{name: name, unit: unit}, amount: amount} ->
        %{
          name: "#{name}(#{amount}#{unit})",
          value: unit
        }
    end)
  end

  def autocomplete_unit(unit, nil, user) do
    case String.length(unit) do
      0 ->
        VirtualCrypto.Money.search_currencies_with_asset_by_guild_and_user(
          nil,
          user
        )

      _ ->
        VirtualCrypto.Money.search_currencies_with_asset_by_unit(unit, nil, user)
    end
  end

  def autocomplete_unit(unit, guild_id, user) do
    case String.length(unit) do
      0 ->
        VirtualCrypto.Money.search_currencies_with_asset_by_guild_and_user(
          String.to_integer(guild_id),
          user
        )

      _ ->
        VirtualCrypto.Money.search_currencies_with_asset_by_unit(
          unit,
          String.to_integer(guild_id),
          user
        )
    end
  end

  def handle(_, %{"name" => "unit", "value" => value}, _, payload, _) do
    user = get_user(payload)
    int_user_id = String.to_integer(user["id"])

    autocomplete_unit(value, payload["guild_id"], %DiscordUser{id: int_user_id})
    |> format_currencies_for_unit
  end
end
