defmodule VirtualCryptoWeb.Interaction.AutoComplete do
  import VirtualCryptoWeb.Interaction.Util, only: [get_user: 1]
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCryptoWeb.Interaction.AutoComplete

  def handle(_, %{"name" => "unit", "value" => value}, _, payload, _) do
    user = get_user(payload)
    int_user_id = String.to_integer(user["id"])

    AutoComplete.CurrencyUnit.handle(value, payload["guild_id"], %DiscordUser{id: int_user_id})
  end

  def handle(_, %{"name" => "name", "value" => value}, _, payload, _) do
    user = get_user(payload)
    int_user_id = String.to_integer(user["id"])

    AutoComplete.CurrencyName.handle(value, payload["guild_id"], %DiscordUser{id: int_user_id})
  end

  def handle(["claim", subcommand], %{"name" => "id", "value" => value}, _, payload, _)
      when subcommand in ["approve", "deny", "cancel", "show"] do
    user = get_user(payload)
    int_user_id = String.to_integer(user["id"])

    sr_filter_subcommand_map = %{
      "approve" => :received,
      "deny" => :received,
      "cancel" => :claimed,
      "show" => :all
    }

    AutoComplete.ClaimId.handle(
      value,
      payload["guild_id"],
      int_user_id,
      sr_filter_subcommand_map[subcommand]
    )
  end
end
