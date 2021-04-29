defmodule InteractionsControllerTest.Bal do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Bal.Helper
  setup :setup_money

  test "bal user1", %{conn: conn, unit: unit, name: name} = ctx do
    sender = ctx.user1

    conn =
      post_command(
        conn,
        from_guild(sender)
      )

    content = ~s"所持通貨一覧
```yaml
#{name}: 199500 #{unit}
```"

    assert %{
             "data" => %{
               "content" => ^content,
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "bal user2", %{conn: conn, unit: unit, name: name, unit2: unit2, name2: name2} = ctx do
    sender = ctx.user2

    conn =
      post_command(
        conn,
        from_guild(sender)
      )

    content = ~s"所持通貨一覧
```yaml
#{name}: 1000 #{unit}
#{name2}: 200000 #{unit2}
```"

    assert %{
             "data" => %{
               "content" => ^content,
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "bal nothing user", %{conn: conn} do

    conn =
      post_command(
        conn,
        from_guild(-1)
      )

    content = ~s"所持通貨一覧
```
通貨を持っていません。
```"

    assert %{
             "data" => %{
               "content" => ^content,
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end
end
