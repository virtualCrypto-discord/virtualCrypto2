defmodule InteractionsControllerTest.Claim.Deny do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import Enum, only: [at: 2]
  import InteractionsControllerTest.Claim.Helper
  setup :setup_claim

  test "deny pending claim by payer", %{conn: conn, claims: claims, user2: user2} do
    claim_id = (claims |> at(0) |> Map.fetch!(:claim)).id
    claim_id_str = to_string(claim_id)

    conn =
      execute_interaction(
        conn,
        patch_from_guild("deny", claim_id, user2)
      )

    assert %{
             "data" => %{"content" => content, "flags" => 64},
             "type" => 4
           } = json_response(conn, 200)

    regex = ~r/id: (\d+)の請求を拒否しました。/
    assert [_, ^claim_id_str] = Regex.run(regex, content)
  end

  test "deny pending claim by claimant", %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, "deny", claims |> at(0) |> Map.fetch!(:claim), user1)
  end

  test "deny pending claim by not related user", %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "deny", claims |> at(0) |> Map.fetch!(:claim), -1)
  end

  test "deny approved claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, "deny", claims |> approved_claim() |> Map.fetch!(:claim), user2)
  end

  test "deny approved claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, "deny", claims |> approved_claim() |> Map.fetch!(:claim), user1)
  end

  test "deny approved claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "deny", claims |> approved_claim() |> Map.fetch!(:claim), -1)
  end

  test "deny denied claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, "deny", claims |> denied_claim() |> Map.fetch!(:claim), user2)
  end

  test "deny denied claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, "deny", claims |> denied_claim() |> Map.fetch!(:claim), user1)
  end

  test "deny denied claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "deny", claims |> denied_claim() |> Map.fetch!(:claim), -1)
  end

  test "deny canceled claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, "deny", claims |> canceled_claim() |> Map.fetch!(:claim), user2)
  end

  test "deny canceled claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, "deny", claims |> canceled_claim() |> Map.fetch!(:claim), user1)
  end

  test "deny canceled claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, "deny", claims |> canceled_claim() |> Map.fetch!(:claim), -1)
  end

  test "deny invalid id claim",
       %{conn: conn, user1: user1} do
    conn =
      execute_interaction(
        conn,
        patch_from_guild("deny", -1, user1)
      )

    assert_discord_message(conn, "エラー: そのidの請求は見つかりませんでした。")
  end
end
