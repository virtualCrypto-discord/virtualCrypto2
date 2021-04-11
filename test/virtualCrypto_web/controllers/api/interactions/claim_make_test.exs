defmodule InteractionsControllerTest.Claim.Make do
  use VirtualCryptoWeb.InteractionsCase, async: true
  setup :setup_claim

  test "valid request from guild", %{conn: conn, user1: user1, user2: user2, unit: unit} do
    conn =
      post_command(
        conn,
        %{
          type: 2,
          data: %{
            name: "claim",
            options: [
              %{
                name: "make",
                options: [
                  %{
                    name: "user",
                    value: to_string(user1)
                  },
                  %{
                    name: "unit",
                    value: unit
                  },
                  %{
                    name: "amount",
                    value: 100
                  }
                ]
              }
            ]
          },
          member: %{
            user: %{
              id: to_string(user2)
            }
          }
        }
      )

    assert %{"data" => %{"content" => content, "flags" => 64}, "type" => 4} =
             json_response(conn, 200)

    regex = ~r/請求id: (\d+) で請求を受け付けました。`\/claim list`でご確認ください。/
    assert [_, claim_id] = Regex.run(regex, content)

    assert {%{amount: 100}, %{unit: ^unit}, %{discord_id: ^user2}, %{discord_id: ^user1}} =
             VirtualCrypto.Money.get_claim_by_id(claim_id)
  end
end
