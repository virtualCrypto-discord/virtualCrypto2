defmodule InteractionsControllerTest.Claim.Patch do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import Enum, only: [at: 2]

  setup :setup_claim

  defp claim_data(action, id) do
    %{
      name: "claim",
      options: [
        %{
          name: action,
          options: [
            %{
              name: "id",
              value: id
            }
          ]
        }
      ]
    }
  end

  defp patch_from_guild(action, id, user) do
    %{
      type: 2,
      data: claim_data(action, id),
      member: %{
        user: %{
          id: to_string(user)
        }
      }
    }
  end

  test "approve pending claim by claimant", %{conn: conn, claims: claims, user1: user1} do
    conn =
      post_command(
        conn,
        patch_from_guild("approve", (claims |> at(0) |> elem(0)).id, user1)
      )

    assert %{
             "data" => %{"content" => "エラー: この請求に対してこの操作を行う権限がありません。", "flags" => 64},
             "type" => 4
           } = json_response(conn, 200)
  end

  test "approve pending claim by payer", %{
    conn: conn,
    claims: claims,
    user1: user1,
    user2: user2,
    currency: currency
  } do
    claim_id = (claims |> at(0) |> elem(0)).id
    claim_id_str = to_string(claim_id)

    before_claimant =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: user1,
        currency: currency
      )

    before_payer =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: user2,
        currency: currency
      )

    conn =
      post_command(
        conn,
        patch_from_guild("approve", claim_id, user2)
      )

    assert %{
             "data" => %{"content" => content, "flags" => 64},
             "type" => 4
           } = json_response(conn, 200)

    regex = ~r/id: (\d+)の請求を承諾し、支払いました。/
    assert [_, ^claim_id_str] = Regex.run(regex, content)
    assert (VirtualCrypto.Money.get_claim_by_id(claim_id) |> elem(0)).status == "approved"

    after_claimant =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: user1,
        currency: currency
      )

    after_payer =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: user2,
        currency: currency
      )

    assert unless(before_claimant == nil, do: before_claimant.asset.amount, else: 0) + 500 ==
             after_claimant.asset.amount

    assert after_payer == nil || before_payer.asset.amount - 500 == after_payer.asset.amount
  end

  test "deny claim by claimant", %{conn: conn, claims: claims, user1: user1} do
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

  test "deny claim by payer", %{conn: conn, claims: claims, user2: user2} do
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
end
