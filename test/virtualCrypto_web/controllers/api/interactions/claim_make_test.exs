defmodule InteractionsControllerTest.Claim.Make do
  use VirtualCryptoWeb.InteractionsCase, async: true
  setup :setup_claim

  test "valid request from guild", %{conn: conn, user1: user1,user2: user2, unit: unit} do
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

    assert %{"data" => %{"content" => content, "flags" => 64},"type" => 4} = json_response(conn, 200)
    assert Regex.match?(~r/請求id: \d+ で請求を受け付けました。`\/claim list`でご確認ください。/,content)
  end
end
