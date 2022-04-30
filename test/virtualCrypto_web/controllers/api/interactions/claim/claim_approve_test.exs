defmodule InteractionsControllerTest.Claim.Approve do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import Enum, only: [at: 2]
  use InteractionsControllerTest.Claim.Helper
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  setup :setup_claim

  test "approve pending claim by payer", %{
    conn: conn,
    claims: claims,
    user1: user1,
    user2: user2,
    currency: currency
  } do
    claim_id = (claims |> at(0) |> Map.fetch!(:claim)).id
    claim_id_str = to_string(claim_id)

    before_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: currency
      )

    before_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: currency
      )

    conn =
      execute_interaction(
        conn,
        patch_from_guild("approve", claim_id, user2)
      )

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "description" => content
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)

    regex = ~r/id: (\d+)の請求を承諾し、支払いました。/
    assert [_, ^claim_id_str] = Regex.run(regex, content)
    assert VirtualCrypto.Money.Query.Claim.get_claim_by_id(claim_id).claim.status == "approved"

    after_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: currency
      )

    after_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: currency
      )

    assert unless(before_claimant == nil, do: before_claimant.asset.amount, else: 0) + 500 ==
             after_claimant.asset.amount

    assert after_payer == nil || before_payer.asset.amount - 500 == after_payer.asset.amount
  end

  test "approve pending claim by claimant", %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, "approve", claims |> at(0) |> Map.fetch!(:claim), user1)
  end

  test "approve pending claim by not related user", %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "approve", claims |> at(0) |> Map.fetch!(:claim), -1)
  end

  test "approve claim by payer but not_enough_amount",
       %{conn: conn, claims: claims, user1: user1} do
    conn =
      execute_interaction(
        conn,
        patch_from_guild("approve", (claims |> at(1) |> Map.fetch!(:claim)).id, user1)
      )

    assert_discord_message(conn, "お金が足りません。")
  end

  test "approve pending claim by claimant not_enough_amount", %{
    conn: conn,
    claims: claims,
    user2: user2
  } do
    test_invalid_operator(conn, "approve", claims |> at(1) |> Map.fetch!(:claim), user2)
  end

  test "approve pending claim by not related user not_enough_amount", %{
    conn: conn,
    claims: claims
  } do
    test_invalid_operator(conn, "approve", claims |> at(1) |> Map.fetch!(:claim), -1)
  end

  test "approve approved claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, "approve", claims |> approved_claim() |> Map.fetch!(:claim), user2)
  end

  test "approve approved claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(
      conn,
      "approve",
      claims |> approved_claim() |> Map.fetch!(:claim),
      user1
    )
  end

  test "approve approved claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "approve", claims |> approved_claim() |> Map.fetch!(:claim), -1)
  end

  test "approve denied claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, "approve", claims |> denied_claim() |> Map.fetch!(:claim), user2)
  end

  test "approve denied claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, "approve", claims |> denied_claim() |> Map.fetch!(:claim), user1)
  end

  test "approve denied claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "approve", claims |> denied_claim() |> Map.fetch!(:claim), -1)
  end

  test "approve canceled claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, "approve", claims |> canceled_claim() |> Map.fetch!(:claim), user2)
  end

  test "approve canceled claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(
      conn,
      "approve",
      claims |> canceled_claim() |> Map.fetch!(:claim),
      user1
    )
  end

  test "approve canceled claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "approve", claims |> canceled_claim() |> Map.fetch!(:claim), -1)
  end

  test "approve invalid id claim",
       %{conn: conn, user1: user1} do
    conn =
      execute_interaction(
        conn,
        patch_from_guild("approve", -1, user1)
      )

    assert_discord_message(conn, "そのidの請求は見つかりませんでした。")
  end
end
