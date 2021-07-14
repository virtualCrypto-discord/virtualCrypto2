defmodule VirtualCryptoWeb.Interaction.SelectMenu do
  alias VirtualCryptoWeb.Interaction.Claim.Helper
  alias VirtualCryptoWeb.Interaction.Claim.Component
  alias VirtualCryptoWeb.Interaction.Claim.List.Options

  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser

  defp handle_(binary, user, selected_claim_ids) do
    {options, rest} = Options.parse(binary)

    <<num::integer, rest::binary>> = rest
    size = num * 8
    <<claim_ids::binary-size(size), _::binary>> = rest
    claim_ids = Helper.destructuring_claim_ids(claim_ids)

    claims =
      VirtualCrypto.Money.get_claim_by_ids(claim_ids)
      |> Enum.map(fn %{claim: %{id: id}} = m ->
        m |> Map.put(:selected, id in selected_claim_ids)
      end)

    int_discord_user_id = String.to_integer(user["id"])
    unless claims |> Enum.all?(fn claim -> int_discord_user_id in [claim.payer.discord_id,claim.claimant.discord_id] end) do
      raise ArgumentError, message: "Illegal request"
    end

    assets = VirtualCrypto.Money.balance(user: %DiscordUser{id: int_discord_user_id})

    {"claim",
     {:ok, :select, %{claims: claims, assets: assets, options: options, me: int_discord_user_id}}}
  end

  def handle(
        [:claim, :select],
        binary,
        [],
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    {options, <<num::integer, rest::binary>>} = Options.parse(binary)
    size = num * 8

    <<_claim_ids::binary-size(size), _::binary>> = rest

    Component.page(user, options)
  end

  def handle(
        [:claim, :select],
        data,
        values,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    handle_(data, user, values |> Enum.map(&String.to_integer/1))
  end
end
