defmodule VirtualCryptoWeb.Interaction.AutoComplete.ClaimId do
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser

  defp arrow(exec, payer, claimant) when exec == payer and exec == claimant do
    "↔"
  end

  defp arrow(exec, payer, _claimant) when exec == payer do
    "➡️"
  end

  defp arrow(exec, _payer, claimant) when exec == claimant do
    "⬅"
  end

  defp format(currencies, executor_discord_id) do
    currencies
    |> Enum.map(fn
      %{
        currency: %{unit: unit},
        claim: %{amount: amount, id: id},
        payer: %{discord_id: payer_discord_id},
        claimant: %{discord_id: claimant_discord_id}
      } ->
        arrow = arrow(executor_discord_id, payer_discord_id, claimant_discord_id)

        %{
          name: "#{id}(#{amount}#{unit}#{arrow})",
          value: id
        }
    end)
  end

  defp list_candidates(claim_id, guild_id, user, sr_filter) do
    VirtualCrypto.Money.search_claims(user, to_string(claim_id), sr_filter, guild_id, 25)
  end

  def handle(claim_id, guild_id, user_discord_id, sr_filter) do
    user = %DiscordUser{id: user_discord_id}

    list_candidates(claim_id, guild_id, user, sr_filter)
    |> format(user_discord_id)
  end
end
