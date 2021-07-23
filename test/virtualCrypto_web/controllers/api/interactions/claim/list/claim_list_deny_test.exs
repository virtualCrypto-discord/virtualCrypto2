defmodule InteractionsControllerTest.Claim.List.Deny do
  use VirtualCryptoWeb.InteractionsCase, async: true
  use InteractionsControllerTest.Claim.List.Helper, action: :deny
  alias VirtualCryptoWeb.Interaction.CustomId
  alias VirtualCryptoWeb.Interaction.CustomId.UI.Button
  alias VirtualCryptoWeb.Interaction.Claim.List.Options, as: ListOptions
  alias VirtualCryptoWeb.Interaction.Claim.List.Helper
  import Enum, only: [at: 2]

  setup :setup_claim

  setup :fake_api

  test "deny pending claim by payer", %{conn: conn, claims: claims, user2: user2} do
    claim = claims |> at(0)

    encoded_claims_ids = Helper.encode_claim_ids([claim])

    options = %ListOptions{
      approved: false,
      canceled: false,
      denied: false,
      pending: true,
      page: 1,
      position: :all,
      related_user: 0
    }

    custom_id =
      CustomId.encode(
        Button.claim_action(:deny) <>
          ListOptions.encode(options) <> encoded_claims_ids
      )

    conn =
      execute_interaction(
        conn,
        action_data(
          %{
            custom_id: custom_id
          },
          user2
        )
      )

    assert %{} = json_response(conn, 200)
    assert_received {:webhook, body}

    assert %{
             content: "id: `#{claim.claim.id}` の請求を拒否しました。",
             flags: 64
           } == body
  end

  test "deny pending claim by claimant", %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, [claims |> at(0)], user1)
  end

  test "deny pending claim by not related user", %{conn: conn, claims: claims} do
    test_invalid_operator(conn, [claims |> at(0)], -1)
  end

  test "deny approved claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, [claims |> approved_claim()], user2)
  end

  test "deny approved claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, [claims |> approved_claim()], user1)
  end

  test "deny approved claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, [claims |> approved_claim()], -1)
  end

  test "deny denied claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, [claims |> denied_claim()], user2)
  end

  test "deny denied claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, [claims |> denied_claim()], user1)
  end

  test "deny denied claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, [claims |> denied_claim()], -1)
  end

  test "deny canceled claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    test_invalid_status(conn, [claims |> canceled_claim()], user2)
  end

  test "deny canceled claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    test_invalid_operator(conn, [claims |> canceled_claim()], user1)
  end

  test "deny canceled claim by not related user",
       %{conn: conn, claims: claims} do
    test_invalid_operator(conn, [claims |> canceled_claim()], -1)
  end

  test "deny invalid id claim",
       %{conn: conn, user1: user1} do
    assert %{
             content: "エラー: そのidの請求は見つかりませんでした。",
             flags: 64
           } == test_common(conn, [%{claim: %{id: 0}}], user1)
  end
end
