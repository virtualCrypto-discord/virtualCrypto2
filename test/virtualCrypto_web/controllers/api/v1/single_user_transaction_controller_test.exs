defmodule UserTransactionControllerTest.V1.Single do
  use VirtualCryptoWeb.RestCase, async: true
  setup :setup_money

  defp exec(conn, json) do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> post(Routes.v1_user_transaction_path(conn, :post), json)
  end

  test "invalid token", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["oauth2.register"])

    conn =
      exec(conn, %{
        unit: ctx.unit,
        receiver_discord_id: to_string(ctx.user2),
        amount: to_string(20)
      })

    assert json_response(conn, 403) == %{
             "error" => "insufficient_scope",
             "error_description" => "token_verfication_failed"
           }
  end

  test "empty object", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    conn = exec(conn, %{})

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "missing_parameter"
           }
  end

  test "valid request", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
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

    assert response(conn, 204)

    assert get_amount(ctx.user1, ctx.currency) == b1 - 20

    assert get_amount(ctx.user2, ctx.currency) == b2 + 20
  end

  test "new user", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = counter()
    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = 0

    conn =
      exec(
        conn,
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(20)
        }
      )

    assert response(conn, 204)

    assert get_amount(ctx.user1, ctx.currency) == b1 - 20

    assert get_amount(user2, ctx.currency) == b2 + 20
  end

  test "not enough amount", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = ctx.user2

    conn =
      exec(
        conn,
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(1_000_000)
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_info" => "not_enough_amount"
           }
  end

  test "pay all", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = ctx.user2
    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = get_amount(user2, ctx.currency)

    conn =
      exec(
        conn,
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(b1)
        }
      )

    assert response(conn, 204)

    assert get_amount(ctx.user1, ctx.currency) == 0

    assert get_amount(user2, ctx.currency) == b2 + b1
  end

  test "pay all+1", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = ctx.user2
    b1 = get_amount(ctx.user1, ctx.currency)

    conn =
      exec(
        conn,
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(b1 + 1)
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_info" => "not_enough_amount"
           }
  end
end
