defmodule InteractionsControllerTest.Pay do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Pay.Helper
  setup :setup_money
  @color_ok 0x38EA42

  test "invalid unit", %{conn: conn} = ctx do
    receiver = ctx.user2

    sender = ctx.user1
    amount = get_amount(sender, ctx.currency)

    conn =
      execute_interaction(
        conn,
        from_guild(%{receiver: receiver, amount: amount, unit: "void"}, sender)
      )

    assert %{
             "data" => %{
               "content" => "エラー: 通貨は存在しません。",
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "invalid amount", %{conn: conn} = ctx do
    receiver = ctx.user2

    sender = ctx.user1

    conn =
      execute_interaction(
        conn,
        from_guild(%{receiver: receiver, amount: -1, unit: ctx.unit}, sender)
      )

    assert %{
             "data" => %{
               "content" => "エラー: 不正な金額です。",
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "valid request", %{conn: conn, unit: unit} = ctx do
    amount = 20
    amount_str = to_string(amount)

    receiver = ctx.user2
    receiver_str = to_string(receiver)

    sender = ctx.user1
    sender_str = to_string(sender)

    b1 = get_amount(sender, ctx.currency)
    b2 = get_amount(receiver, ctx.currency)

    conn =
      execute_interaction(
        conn,
        from_guild(%{receiver: receiver, amount: amount, unit: unit}, sender)
      )

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => @color_ok,
                   "description" => desc
                 }
               ]
             },
             "type" => 4
           } = json_response(conn, 200)

    [_, ^sender_str, ^receiver_str, ^amount_str, ^unit] =
      Regex.run(~r/\<@(\d*)\>から\<@(\d*)\>へ\*\*(\d*)\*\* \`(.*)\`送金されました。/, desc)

    assert get_amount(sender, ctx.currency) == b1 - amount

    assert get_amount(receiver, ctx.currency) == b2 + amount
  end

  test "new user", %{conn: conn, unit: unit} = ctx do
    amount = 20
    amount_str = to_string(amount)

    receiver = -1
    receiver_str = to_string(receiver)

    sender = ctx.user1
    sender_str = to_string(sender)

    b1 = get_amount(sender, ctx.currency)
    b2 = 0

    conn =
      execute_interaction(
        conn,
        from_guild(%{receiver: receiver, amount: amount, unit: unit}, sender)
      )

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => @color_ok,
                   "description" => desc
                 }
               ]
             },
             "type" => 4
           } = json_response(conn, 200)

    [_, ^sender_str, ^receiver_str, ^amount_str, ^unit] =
      Regex.run(~r/\<@(\d*)\>から\<@([0-9\-]*)\>へ\*\*(\d*)\*\* \`(.*)\`送金されました。/, desc)

    assert get_amount(sender, ctx.currency) == b1 - amount

    assert get_amount(receiver, ctx.currency) == b2 + amount
  end

  test "not enough amount", %{conn: conn} = ctx do
    amount = 1_000_000

    receiver = ctx.user2

    sender = ctx.user1

    conn =
      execute_interaction(
        conn,
        from_guild(%{receiver: receiver, amount: amount, unit: ctx.unit}, sender)
      )

    assert %{
             "data" => %{
               "content" => "エラー: 通貨が不足しています。",
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "pay all", %{conn: conn} = ctx do
    unit = ctx.unit

    receiver = ctx.user2
    receiver_str = to_string(receiver)

    sender = ctx.user1
    sender_str = to_string(sender)

    b1 = get_amount(sender, ctx.currency)
    b2 = get_amount(receiver, ctx.currency)

    amount = b1
    amount_str = to_string(b1)

    conn =
      execute_interaction(
        conn,
        from_guild(%{receiver: receiver, amount: amount, unit: unit}, sender)
      )

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => @color_ok,
                   "description" => desc
                 }
               ]
             },
             "type" => 4
           } = json_response(conn, 200)

    assert [_, ^sender_str, ^receiver_str, ^amount_str, ^unit] =
             Regex.run(~r/\<@(\d*)\>から\<@([0-9\-]*)\>へ\*\*(\d*)\*\* \`(.*)\`送金されました。/, desc)

    assert get_amount(sender, ctx.currency) == 0

    assert get_amount(receiver, ctx.currency) == b2 + amount
  end

  test "pay all+1", %{conn: conn} = ctx do
    receiver = ctx.user2

    sender = ctx.user1
    amount = get_amount(sender, ctx.currency) + 1

    conn =
      execute_interaction(
        conn,
        from_guild(%{receiver: receiver, amount: amount, unit: ctx.unit}, sender)
      )

    assert %{
             "data" => %{
               "content" => "エラー: 通貨が不足しています。",
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "amount by string", %{conn: conn} = ctx do
    receiver = ctx.user2

    sender = ctx.user1

    conn =
      execute_interaction(
        conn,
        from_guild(%{receiver: receiver, amount: "9007199254740992", unit: ctx.unit}, sender)
      )

    assert %{
             "data" => %{
               "content" => "エラー: 通貨が不足しています。",
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end
end
