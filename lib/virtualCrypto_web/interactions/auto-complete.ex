defmodule VirtualCryptoWeb.Interaction.AutoComplete do
  defp format_currencies_for_unit(currencies) do
    currencies
    |> Enum.map(
      &%{
        name: "#{&1.name}(#{&1.unit})",
        value: &1.unit
      }
    )
  end

  def autocomplete_unit(unit, nil) do
    case String.length(unit) do
      0 -> []
      _ -> VirtualCrypto.Money.search_currencies_by_unit(unit)
    end
  end

  def autocomplete_unit(unit, guild_id) do
    case String.length(unit) do
      0 -> VirtualCrypto.Money.search_currencies_by_guild(String.to_integer(guild_id))
      _ -> VirtualCrypto.Money.search_currencies_by_unit(unit)
    end
  end

  def handle(_, %{"name" => "unit", "value" => value}, _, params, _) do
    autocomplete_unit(value, params["guild_id"]) |> format_currencies_for_unit
  end
end
