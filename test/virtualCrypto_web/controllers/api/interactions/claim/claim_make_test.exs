defmodule InteractionsControllerTest.Claim.Make do
  use VirtualCryptoWeb.InteractionsCase, async: true
  setup :setup_claim

  defp claim_data(%{payer: payer, unit: unit, amount: amount}) do
    %{
      name: "claim",
      options: [
        %{
          name: "make",
          options: [
            %{
              name: "user",
              value: to_string(payer)
            },
            %{
              name: "unit",
              value: unit
            },
            %{
              name: "amount",
              value: amount
            }
          ]
        }
      ]
    }
  end

  defp make_from_guild(%{payer: payer, claimant: claimant, unit: unit, amount: amount}) do
    %{
      type: 2,
      data: claim_data(%{payer: payer, unit: unit, amount: amount}),
      member: %{
        user: %{
          id: to_string(claimant)
        }
      }
    }
  end

  test "valid request from guild", %{conn: conn, user1: user1, user2: user2, unit: unit} do
    amount = 100

    conn =
      execute_interaction(
        conn,
        make_from_guild(%{claimant: user2, payer: user1, unit: unit, amount: amount})
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

    regex = ~r/請求id: (\d+) で請求を受け付けました。`\/claim show id:\d+`でご確認ください。/
    assert [_, claim_id] = Regex.run(regex, content)

    assert %{
             claim: %{amount: ^amount},
             currency: %{unit: ^unit},
             claimant: %{discord_id: ^user2},
             payer: %{discord_id: ^user1}
           } = VirtualCrypto.Money.Query.Claim.get_claim_by_id(claim_id)
  end

  test "invalid amount", %{conn: conn, user1: user1, user2: user2, unit: unit} do
    amount = -100

    conn =
      execute_interaction(
        conn,
        make_from_guild(%{claimant: user2, payer: user1, unit: unit, amount: amount})
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

    assert content == "不正な金額です。1以上9223372036854775807以下である必要があります。"
  end

  test "invalid unit", %{conn: conn, user1: user1, user2: user2} do
    amount = 100

    conn =
      execute_interaction(
        conn,
        make_from_guild(%{claimant: user2, payer: user1, unit: "void", amount: amount})
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

    assert content == "指定された通貨は存在しません。"
  end
end
