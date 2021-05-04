defmodule UserTransactionControllerTest.V2.Pay.Bulk do
  use VirtualCryptoWeb.RestCase, async: true
  setup :setup_money

  defp exec(conn, json) do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
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

  test "empty array", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    conn = exec(conn, [])

    assert response(conn, 201)
  end

  test "one element", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = get_amount(ctx.user2, ctx.currency)

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(ctx.user2),
          amount: to_string(20)
        }
      ])

    assert response(conn, 201)

    assert get_amount(ctx.user1, ctx.currency) == b1 - 20

    assert get_amount(ctx.user2, ctx.currency) == b2 + 20
  end

  test "one element new user", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = counter()
    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = 0

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(20)
        }
      ])

    assert response(conn, 201)

    assert get_amount(ctx.user1, ctx.currency) == b1 - 20

    assert get_amount(user2, ctx.currency) == b2 + 20
  end

  test "two element new user", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = counter()
    user3 = counter()
    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = 0
    b3 = 0

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(20)
        },
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user3),
          amount: to_string(30)
        }
      ])

    assert response(conn, 201)

    assert get_amount(ctx.user1, ctx.currency) == b1 - 50

    assert get_amount(user2, ctx.currency) == b2 + 20
    assert get_amount(user3, ctx.currency) == b3 + 30
  end

  test "two element mix user", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = ctx.user2
    user3 = counter()
    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = get_amount(user2, ctx.currency)
    b3 = 0

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(20)
        },
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user3),
          amount: to_string(30)
        }
      ])

    assert response(conn, 201)

    assert get_amount(ctx.user1, ctx.currency) == b1 - 50

    assert get_amount(user2, ctx.currency) == b2 + 20
    assert get_amount(user3, ctx.currency) == b3 + 30
  end

  test "two element mix currency", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.pay"])
    userA = counter()
    userB = counter()
    b1_c1 = get_amount(ctx.user2, ctx.currency)
    b1_c2 = get_amount(ctx.user2, ctx.currency2)
    b2 = 0
    b3 = 0

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(userA),
          amount: to_string(20)
        },
        %{
          unit: ctx.unit2,
          receiver_discord_id: to_string(userB),
          amount: to_string(30)
        }
      ])

    assert response(conn, 201)

    assert get_amount(ctx.user2, ctx.currency) == b1_c1 - 20
    assert get_amount(ctx.user2, ctx.currency2) == b1_c2 - 30

    assert get_amount(userA, ctx.currency) == b2 + 20
    assert get_amount(userB, ctx.currency2) == b3 + 30
  end

  test "two element mix currency mix user", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.pay"])
    userA = counter()
    userB = counter()
    userC = counter()
    b1_c1 = get_amount(ctx.user2, ctx.currency)
    b1_c2 = get_amount(ctx.user2, ctx.currency2)

    conn =
      exec(conn, [
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
      ])

    assert response(conn, 201)

    assert get_amount(ctx.user2, ctx.currency) == b1_c1 - 40
    assert get_amount(ctx.user2, ctx.currency2) == b1_c2 - 40

    assert get_amount(userA, ctx.currency) == 20
    assert get_amount(userB, ctx.currency) == 20
    assert get_amount(userB, ctx.currency2) == 30
    assert get_amount(userC, ctx.currency2) == 10
  end

  test "not enough amount", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = ctx.user2
    user3 = counter()

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(1_000_000)
        },
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user3),
          amount: to_string(30)
        }
      ])

    assert json_response(conn, 409) == %{
             "error" => "conflict",
             "error_info" => "not_enough_amount"
           }
  end

  test "not enough amount2", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = ctx.user2
    user3 = counter()

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(100_000)
        },
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user3),
          amount: to_string(100_000)
        }
      ])

    assert json_response(conn, 409) == %{
             "error" => "conflict",
             "error_info" => "not_enough_amount"
           }
  end

  test "pay all", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = ctx.user2
    b1 = get_amount(ctx.user1, ctx.currency)
    b2 = get_amount(user2, ctx.currency)

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(b1)
        }
      ])

    assert response(conn, 201)

    assert get_amount(ctx.user1, ctx.currency) == 0

    assert get_amount(user2, ctx.currency) == b2 + b1
  end

  test "pay all+1", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.pay"])
    user2 = ctx.user2
    b1 = get_amount(ctx.user1, ctx.currency)

    conn =
      exec(conn, [
        %{
          unit: ctx.unit,
          receiver_discord_id: to_string(user2),
          amount: to_string(b1 + 1)
        }
      ])

    assert json_response(conn, 409) == %{
             "error" => "conflict",
             "error_info" => "not_enough_amount"
           }
  end
end
