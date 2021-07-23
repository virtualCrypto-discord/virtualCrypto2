defmodule InteractionsControllerTest.Claim.List.Approve do
  use VirtualCryptoWeb.InteractionsCase, async: true
  use InteractionsControllerTest.Claim.List.Helper, action: :approve
  alias VirtualCryptoWeb.Interaction.CustomId
  alias VirtualCryptoWeb.Interaction.CustomId.UI.Button
  alias VirtualCryptoWeb.Interaction.Claim.List.Options, as: ListOptions
  alias VirtualCryptoWeb.Interaction.Claim.List.Helper
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  import VirtualCryptoWeb.Api.InteractionsView.Util
  import Enum, only: [at: 2]

  setup :setup_claim

  setup :fake_api

  test "approve pending claim by payer", %{
    conn: conn,
    claims: claims,
    user1: user1,
    user2: user2,
    currency: currency,
    unit: unit
  } do
    claim = claims |> at(0)

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
        Button.claim_action(:approve) <>
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

    assert_received {:webhook, body}

    assert %{
             content: "id: `#{claim.claim.id}` の請求を承諾し、支払いました。",
             flags: 64
           } == body

    remaining_claims =
      [remaining_claim] = VirtualCrypto.Money.get_claims(%DiscordUser{id: user2}, ["pending"])

    reload_custom_id =
      CustomId.encode(
        Button.claim_list(:all) <>
          ListOptions.encode(options)
      )

    select_custom_id =
      CustomId.encode(
        Button.claim_list(:all) <>
          ListOptions.encode(options) <> (remaining_claims |> Helper.encode_claim_ids())
      )

    assert %{
             "data" => %{
               "components" => [
                 %{
                   "components" => [
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏪"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏮️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏭️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏩"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => reload_custom_id,
                       "emoji" => %{"name" => "🔄"},
                       "style" => 2,
                       "type" => 2
                     }
                   ],
                   "type" => 1
                 },
                 %{
                   "components" => [
                     %{
                       "custom_id" => select_custom_id,
                       "max_values" => 1,
                       "min_values" => 0,
                       "options" => [
                         %{
                           "default" => false,
                           "description" => "9999999 #{unit}",
                           "label" => "📤#{remaining_claim.claim.id}",
                           "value" => "#{remaining_claim.claim.id}"
                         }
                       ],
                       "type" => 3
                     }
                   ],
                   "type" => 1
                 }
               ],
               "embeds" => [
                 %{
                   "color" => 6_431_213,
                   "description" => nil,
                   "fields" => [
                     %{
                       "name" => "◻️📤#{remaining_claim.claim.id}",
                       "value" =>
                         "状態　: ⌛未決定\n請求額: **9999999** `#{unit}`\n請求元: <@#{user2}>\n請求先: <@#{user1}>\n請求日: #{format_date_time(remaining_claim.claim.inserted_at)}"
                     }
                   ],
                   "title" => "請求一覧(all)"
                 }
               ],
               "flags" => 64
             },
             "type" => 7
           } == json_response(conn, 200)

    assert VirtualCrypto.Money.get_claim_by_id(claim.claim.id).claim.status == "approved"

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
    test_invalid_operator(conn, [claims |> at(0)], user1)
  end

  test "approve pending claim by not related user", %{conn: conn, claims: claims} do
    test_invalid_operator(conn, [claims |> at(0)], -1)
  end

  test "approve claim by payer but not_enough_amount",
       %{conn: conn, claims: claims, user1: user1} do
    claim = claims |> at(1)

    assert %{
             content: "エラー: お金が足りません。",
             flags: 64
           } == test_common(conn, [claim], user1)
  end

  test "approve pending claim by claimant not_enough_amount", %{
    conn: conn,
    claims: claims,
    user2: user2
  } do
    claim = claims |> at(1)
    test_invalid_operator(conn, [claim], user2)
  end

  test "approve pending claim by not related user not_enough_amount", %{
    conn: conn,
    claims: claims
  } do
    claim = claims |> at(1)
    test_invalid_operator(conn, [claim], -1)
  end

  test "approve approved claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    claim = claims |> approved_claim()
    test_invalid_status(conn, [claim], user2)
  end

  test "approve approved claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    claim = claims |> approved_claim()

    test_invalid_operator(conn, [claim], user1)
  end

  test "approve approved claim by not related user",
       %{conn: conn, claims: claims} do
    claim = claims |> approved_claim()

    test_invalid_operator(conn, [claim], -1)
  end

  test "approve denied claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    claim = claims |> denied_claim()

    test_invalid_status(conn, [claim], user2)
  end

  test "approve denied claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    claim = claims |> denied_claim()

    test_invalid_operator(conn, [claim], user1)
  end

  test "approve denied claim by not related user",
       %{conn: conn, claims: claims} do
    claim = claims |> denied_claim()

    test_invalid_operator(conn, [claim], -1)
  end

  test "approve canceled claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    claim = claims |> canceled_claim()

    test_invalid_status(conn, [claim], user2)
  end

  test "approve canceled claim by claimant",
       %{conn: conn, claims: claims, user1: user1} do
    claim = claims |> canceled_claim()

    test_invalid_operator(conn, [claim], user1)
  end

  test "approve canceled claim by not related user",
       %{conn: conn, claims: claims} do
    claim = claims |> canceled_claim()

    test_invalid_operator(conn, [claim], -1)
  end

  test "approve invalid id claim",
       %{conn: conn, user1: user1} do
    assert %{
             content: "エラー: そのidの請求は見つかりませんでした。",
             flags: 64
           } == test_common(conn, [%{claim: %{id: 0}}], user1)
  end
end
