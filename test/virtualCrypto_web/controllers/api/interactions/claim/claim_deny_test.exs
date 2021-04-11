defmodule InteractionsControllerTest.Claim.Deny do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import Enum, only: [at: 2]
  import InteractionsControllerTest.Claim.Patch
  setup :setup_claim

  test "deny pending claim by claimant", %{conn: conn, claims: claims, user1: user1} do
    conn =
      post_command(
        conn,
        patch_from_guild("deny", (claims |> at(0) |> elem(0)).id, user1)
      )

    assert %{
             "data" => %{"content" => "エラー: この請求に対してこの操作を行う権限がありません。", "flags" => 64},
             "type" => 4
           } = json_response(conn, 200)
  end

  test "deny pending claim by not related user", %{conn: conn, claims: claims} do
    conn =
      post_command(
        conn,
        patch_from_guild("deny", (claims |> at(0) |> elem(0)).id, -1)
      )

    assert %{
             "data" => %{"content" => "エラー: この請求に対してこの操作を行う権限がありません。", "flags" => 64},
             "type" => 4
           } = json_response(conn, 200)
  end

  test "deny pending claim by payer", %{conn: conn, claims: claims, user2: user2} do
    claim_id = (claims |> at(0) |> elem(0)).id
    claim_id_str = to_string(claim_id)

    conn =
      post_command(
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

  test "deny approved claim",
       %{conn: conn, claims: claims, user2: user2} do
    conn =
      post_command(
        conn,
        patch_from_guild("deny", (claims |> approved_claim() |> elem(0)).id, user2)
      )

    assert %{
             "data" => %{
               "content" => "エラー: この請求に対してこの操作を行うことは出来ません。",
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "deny denied claim",
       %{conn: conn, claims: claims, user2: user2} do
    conn =
      post_command(
        conn,
        patch_from_guild("deny", (claims |> denied_claim() |> elem(0)).id, user2)
      )

    assert %{
             "data" => %{
               "content" => "エラー: この請求に対してこの操作を行うことは出来ません。",
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "deny canceled claim",
       %{conn: conn, claims: claims, user2: user2} do
    conn =
      post_command(
        conn,
        patch_from_guild("deny", (claims |> canceled_claim() |> elem(0)).id, user2)
      )

    assert %{
             "data" => %{
               "content" => "エラー: この請求に対してこの操作を行うことは出来ません。",
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end
end
