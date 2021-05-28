defmodule InteractionsControllerTest.Claim.Cancel do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import Enum, only: [at: 2]
  import InteractionsControllerTest.Claim.Helper
  setup :setup_claim

  test "cancel pending claim by claimant", %{conn: conn, claims: claims, user1: user1} do
    claim_id = (claims |> at(0) |> Map.fetch!(:claim)).id
    claim_id_str = to_string(claim_id)

    conn =
      post_command(
        conn,
        patch_from_guild("cancel", claim_id, user1)
      )

    assert %{
             "data" => %{"content" => content, "flags" => 64},
             "type" => 4
           } = json_response(conn, 200)

    regex = ~r/id: (\d+)の請求をキャンセルしました。/
    assert [_, ^claim_id_str] = Regex.run(regex, content)
  end

  test "cancel pending claim by payer", %{conn: conn, claims: claims, user2: user2} do
    test_invalid_operator(conn, "cancel", claims |> at(0) |> Map.fetch!(:claim), user2)
  end

  test "cancel pending claim by not related user", %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "cancel", claims |> at(0) |> Map.fetch!(:claim), -1)
  end

  test "cancel approved claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_status(conn, "cancel", claims |> approved_claim() |> Map.fetch!(:claim), user1)
  end

  test "cancel approved claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_operator(conn, "cancel", claims |> approved_claim() |> Map.fetch!(:claim), user2)
  end

  test "cancel approved claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "cancel", claims |> approved_claim() |> Map.fetch!(:claim), -1)
  end

  test "cancel denied claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_status(conn, "cancel", claims |> denied_claim() |> Map.fetch!(:claim), user1)
  end

  test "cancel denied claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_operator(conn, "cancel", claims |> denied_claim() |> Map.fetch!(:claim), user2)
  end

  test "cancel denied claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "cancel", claims |> denied_claim() |> Map.fetch!(:claim), -1)
  end

  test "cancel canceled claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_status(conn, "cancel", claims |> canceled_claim() |> Map.fetch!(:claim), user1)
  end

  test "cancel canceled claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_operator(conn, "cancel", claims |> canceled_claim() |> Map.fetch!(:claim), user2)
  end

  test "cancel canceled claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "cancel", claims |> canceled_claim() |> Map.fetch!(:claim), -1)
  end

  test "cancel invalid id claim",
       %{conn: conn, user1: user1} do
    conn =
      post_command(
        conn,
        patch_from_guild("cancel", -1, user1)
      )

    assert_discord_message(conn, "エラー: そのidの請求は見つかりませんでした。")
  end
end
