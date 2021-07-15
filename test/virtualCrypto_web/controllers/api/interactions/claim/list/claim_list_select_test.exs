defmodule InteractionsControllerTest.Claim.List.Select do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Helper.Common
  alias VirtualCryptoWeb.Interaction.CustomId
  alias VirtualCryptoWeb.Interaction.CustomId.UI.Button
  alias VirtualCryptoWeb.Interaction.CustomId.UI.SelectMenu
  alias VirtualCryptoWeb.Interaction.Claim.List.Options, as: ListOptions
  alias VirtualCryptoWeb.Interaction.Claim.List.Helper
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  setup :setup_claim

  test "selection", %{conn: conn, user1: user1} do
    claims =
      VirtualCrypto.Money.get_claims(
        %DiscordUser{id: user1},
        ["pending"],
        :all,
        nil,
        :desc_claim_id,
        %{page: 1},
        5
      )

    custom_id_select =
      CustomId.encode(
        SelectMenu.claim_select() <>
          ListOptions.encode(%ListOptions{
            approved: false,
            canceled: false,
            denied: false,
            pending: true,
            page: 1,
            position: :all,
            related_user: 0
          }) <> Helper.encode_claim_ids(claims.claims)
      )

    conn =
      execute_interaction(
        conn,
        select_from_guild(%{
          custom_id: custom_id_select,
          values: claims.claims |> Enum.map(& to_string(&1.claim.id))
        },user1)
      )

    IO.inspect(json_response(conn, 200))
  end
end
