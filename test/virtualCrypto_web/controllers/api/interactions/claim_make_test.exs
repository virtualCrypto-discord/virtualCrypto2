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
      data: claim_data(%{payer: payer,unit: unit,amount: amount}),
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
      post_command(
        conn,
        make_from_guild(%{claimant: user2, payer: user1, unit: unit, amount: amount})
      )

    assert %{"data" => %{"content" => content, "flags" => 64}, "type" => 4} =
             json_response(conn, 200)

    regex = ~r/請求id: (\d+) で請求を受け付けました。`\/claim list`でご確認ください。/
    assert [_, claim_id] = Regex.run(regex, content)

    assert {%{amount: ^amount}, %{unit: ^unit}, %{discord_id: ^user2}, %{discord_id: ^user1}} =
             VirtualCrypto.Money.get_claim_by_id(claim_id)
  end

end
