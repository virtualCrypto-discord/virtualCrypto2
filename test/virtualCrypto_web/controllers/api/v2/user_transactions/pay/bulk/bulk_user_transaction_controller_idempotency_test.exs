defmodule UserTransactionControllerTest.V2.Pay.Bulk.Idempotency do
  use VirtualCryptoWeb.RestCase, async: true
  import InteractionsControllerTest.Pay.Helper

  setup :setup_money

  defp exec(conn, json, idempotency_key \\ "1dEmP0104Ke1") do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("idempotency-key", "\"#{idempotency_key}\"")
    |> post(Routes.v2_user_transaction_path(conn, :post), Jason.encode!(json))
  end

  test "useable in bulk request", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.pay"])
    conn2 = set_user_auth(build_rest_conn(), :user, ctx.user2, ["vc.pay"])

    userA = counter()
    userB = counter()
    userC = counter()
    b1_c1 = get_amount(ctx.user2, ctx.currency)
    b1_c2 = get_amount(ctx.user2, ctx.currency2)

    req = [
      %{
        unit: ctx.unit,
        receiver_discord_id: to_string(userA),
        amount: to_string(20)
      },
      %{
        unit: ctx.unit,
        receiver_discord_id: to_string(userB),
        amount: to_string(20)
      },
      %{
        unit: ctx.unit2,
        receiver_discord_id: to_string(userB),
        amount: to_string(30)
      },
      %{
        unit: ctx.unit2,
        receiver_discord_id: to_string(userC),
        amount: to_string(10)
      }
    ]

    conn = exec(conn, req)
    conn2 = exec(conn2, req)
    assert json_response(conn, 201)
    assert json_response(conn2, 201)

    assert idempotency_ok?(conn) != idempotency_ok?(conn2)
    assert idempotency_duplicate?(conn2) != idempotency_duplicate?(conn)

    assert get_amount(ctx.user2, ctx.currency) == b1_c1 - 40
    assert get_amount(ctx.user2, ctx.currency2) == b1_c2 - 40

    assert get_amount(userA, ctx.currency) == 20
    assert get_amount(userB, ctx.currency) == 20
    assert get_amount(userB, ctx.currency2) == 30
    assert get_amount(userC, ctx.currency2) == 10
  end
end
