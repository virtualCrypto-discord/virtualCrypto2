defmodule VirtualCryptoWeb.Interaction.AutoComplete.ClaimId do
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser

  defp user_tag(%{"username" => name, "discriminator" => "0"}) do
    name
  end

  defp user_tag(%{"username" => name, "discriminator" => discriminator}) do
    "#{name}##{discriminator}"
  end

  defp user_tag(nil) do
    "deleted"
  end

  defp claim_status_emoji("approved") do
    "✅"
  end

  defp claim_status_emoji("denied") do
    "❌"
  end

  defp claim_status_emoji("canceled") do
    "🗑️"
  end

  defp claim_status_emoji("pending") do
    "⌛"
  end

  defp format(claims) do
    claims
    |> Enum.map(fn
      %{
        currency: %{unit: unit},
        claim: %{amount: amount, id: id, status: status},
        payer: %{application_id: payer_application_id, discord_id: payer_discord_id},
        claimant: %{application_id: claimant_application_id, discord_id: claimant_discord_id}
      } ->
        [payer, claimant] =
          Task.await_many([
            Task.async(fn ->
              if payer_discord_id do
                user_tag(Discord.Api.Cached.get_user(payer_discord_id))
              else
                "#{VirtualCrypto.Auth.get_application(payer_application_id).application.client_name}(app)"
              end
            end),
            Task.async(fn ->
              if claimant_discord_id do
                user_tag(Discord.Api.Cached.get_user(claimant_discord_id))
              else
                "#{VirtualCrypto.Auth.get_application(claimant_application_id).application.client_name}(app)"
              end
            end)
          ])

        %{
          name:
            "#{claim_status_emoji(status)}  請求id: #{id}  金額: #{amount}#{unit}  請求元: #{claimant}  請求先: #{payer}",
          value: id
        }
    end)
  end

  defp list_candidates(claim_id, guild_id, user, sr_filter, status) do
    VirtualCrypto.Money.search_claims(user, to_string(claim_id), sr_filter, status, guild_id, 25)
  end

  def handle(claim_id, guild_id, user_discord_id, sr_filter, status) do
    user = %DiscordUser{id: user_discord_id}

    list_candidates(claim_id, guild_id, user, sr_filter, status)
    |> format()
  end
end
