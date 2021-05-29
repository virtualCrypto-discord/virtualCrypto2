defmodule VirtualCryptoWeb.Interaction.Claim.List do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Money.DiscordService

  def page(user, n) do
    int_user_id = String.to_integer(user["id"])

    {:ok, "list",
     Money.get_claims(
       DiscordService,
       int_user_id,
       ["pending"],
       :all,
       :desc_claim_id,
       %{page: n},
       5
     )
     |> Map.put(:me, int_user_id)}
  end

  def last(user) do
    int_user_id = String.to_integer(user["id"])

    {:ok, "list",
     Money.get_claims(
       DiscordService,
       int_user_id,
       ["pending"],
       :all,
       :desc_claim_id,
       %{page: :last},
       5
     )
     |> Map.put(:me, int_user_id)}
  end
end
