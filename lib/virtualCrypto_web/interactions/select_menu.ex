defmodule VirtualCryptoWeb.Interaction.SelectMenu do
  alias VirtualCryptoWeb.Interaction.Claim.Helper
  alias VirtualCryptoWeb.Interaction.Claim.Component
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser

  defp handle_(<<num::integer, rest::binary>>, user, selected_claim_ids) do
    size = num * 8
    <<claim_ids::binary-size(size), rest::binary>> = rest

    claim_ids = Helper.destructuring_claim_ids(claim_ids)

    claims =
      VirtualCrypto.Money.get_claim_by_ids(claim_ids)
      |> Enum.map(fn %{claim: %{id: id}} = m ->
        m |> Map.put(:selected, id in selected_claim_ids)
      end)

    int_discord_user_id = String.to_integer(user["id"])
    assets = VirtualCrypto.Money.balance(user: %DiscordUser{id: int_discord_user_id})
    q = Helper.drop_tail_0(rest)

    {"claim",
     {:ok, :select,
      %{claims: claims, assets: assets, query: q |> URI.decode_query(), me: int_discord_user_id}}}
  end

  def handle(
        [:claim, :select],
        <<num::integer, rest::binary>>,
        [],
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    size = num * 8
    <<_claim_ids::binary-size(size), rest::binary>> = rest

    query = Helper.drop_tail_0(rest) |> URI.decode_query()

    Component.page(String.to_atom(Map.fetch!(query, "sc")), query, user)
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
