defmodule UserTransactionControllerTest.Pay.Idempotency.Single do
  use VirtualCryptoWeb.RestCase, async: true
  import InteractionsControllerTest.Pay.Helper

  setup :setup_money

  defp exec(conn, json, idempotency_key \\ "1dEmP0104Ke1") do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("idempotency-key", idempotency_key)
    |> post(Routes.v2_user_transaction_path(conn, :post), Jason.encode!(json))
  end

  test "invalid token", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["oauth2.register"])
    conn = exec(conn, [])

    assert json_response(conn, 403) == %{
             "error" => "insufficient_scope",
             "error_description" => "token_verification_failed"
           }
  end

  test "prevent duplicate request", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    conn2 = set_user_auth(build_rest_conn(), :user, ctx.user1, ["vc.pay"])
    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = get_amount(ctx.user2, ctx.currency)

    conn =
      exec(
        conn,
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(ctx.user2),
          amount: to_string(20)
        }
      )

    conn2 =
      exec(
        conn2,
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(ctx.user2),
          amount: to_string(20)
        }
      )

    assert response(conn, 201)
    assert response(conn2, 201)

    assert idempotency_ok?(conn) != idempotency_ok?(conn2)
    assert idempotency_duplicate?(conn2) != idempotency_duplicate?(conn)

    assert get_amount(ctx.user1, ctx.currency) == b1 - 20

    assert get_amount(ctx.user2, ctx.currency) == b2 + 20
  end

  test "Idempotency-Key is independent for each user", ctx do
    conn = set_user_auth(ctx.conn, :user, ctx.user1, ["vc.pay"])
    conn2 = set_user_auth(build_rest_conn(), :user, ctx.user2, ["vc.pay"])

    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = get_amount(ctx.user2, ctx.currency)

    conn =
      exec(
        conn,
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(ctx.user2),
          amount: to_string(40)
        }
      )

    conn2 =
      exec(
        conn2,
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(ctx.user1),
          amount: to_string(20)
        }
      )

    assert response(conn, 201)
    assert response(conn2, 201)

    assert idempotency_ok?(conn)
    assert idempotency_ok?(conn2)

    assert get_amount(ctx.user1, ctx.currency) == b1 - 20

    assert get_amount(ctx.user2, ctx.currency) == b2 + 20
  end
end
