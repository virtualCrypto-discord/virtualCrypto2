defmodule InteractionsControllerTest.Info do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Info.Helper
  import VirtualCryptoWeb.Api.InteractionsView.Util

  setup :setup_money

  test "info in guild", %{conn: conn, guild: guild, unit: unit, name: name} = ctx do
    conn =
      post_command(
        conn,
        from_guild(ctx.user1, guild)
      )

    assert json_response(conn, 200) == %{
             "data" => %{
               "embeds" => [
                 %{
                   "author" => nil,
                   "color" => color_brand(),
                   "fields" => [
                     %{"inline" => true, "name" => "総発行量", "value" => "`200500#{unit}`"},
                     %{"inline" => true, "name" => "発行枠", "value" => "`500#{unit}`"},
                     %{"inline" => true, "name" => "あなたの所持量", "value" => "`199500#{unit}`"}
                   ],
                   "footer" => %{"text" => "発行枠は一日一回総発行量の0.5%増加し、最大で総発行量の3.5%となります。"},
                   "title" => name
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           }
  end

  test "info in guild not hold", %{conn: conn, guild: guild, unit: unit, name: name} do
    conn =
      post_command(
        conn,
        from_guild(-1, guild)
      )

    assert json_response(conn, 200) == %{
             "data" => %{
               "embeds" => [
                 %{
                   "author" => nil,
                   "color" => color_brand(),
                   "fields" => [
                     %{"inline" => true, "name" => "総発行量", "value" => "`200500#{unit}`"},
                     %{"inline" => true, "name" => "発行枠", "value" => "`500#{unit}`"},
                     %{"inline" => true, "name" => "あなたの所持量", "value" => "`0#{unit}`"}
                   ],
                   "footer" => %{"text" => "発行枠は一日一回総発行量の0.5%増加し、最大で総発行量の3.5%となります。"},
                   "title" => name
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           }
  end

  test "info in guild error", %{conn: conn} = ctx do
    conn =
      post_command(
        conn,
        from_guild(ctx.user1, -1)
      )

    assert json_response(conn, 200) == %{
             "data" => %{
               "allowed_mentions" => %{"parse" => []},
               "embeds" => [
                 %{"color" => color_error(), "description" => "通貨が見つかりませんでした。", "title" => "エラー"}
               ],
               "flags" => 64
             },
             "type" => 4
           }
  end

  test "info by unit", %{conn: conn, unit: unit, name: name} = ctx do
    conn =
      post_command(
        conn,
        from_guild_unit(unit, ctx.user1, -1)
      )

    assert json_response(conn, 200) == %{
             "data" => %{
               "embeds" => [
                 %{
                   "author" => nil,
                   "color" => color_brand(),
                   "fields" => [
                     %{"inline" => true, "name" => "総発行量", "value" => "`200500#{unit}`"},
                     %{"inline" => true, "name" => "発行枠", "value" => "`500#{unit}`"},
                     %{"inline" => true, "name" => "あなたの所持量", "value" => "`199500#{unit}`"}
                   ],
                   "footer" => %{"text" => "発行枠は一日一回総発行量の0.5%増加し、最大で総発行量の3.5%となります。"},
                   "title" => name
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           }
  end

  test "info by unit error", %{conn: conn} = ctx do
    conn =
      post_command(
        conn,
        from_guild_unit("gao", ctx.user1, -1)
      )

    assert json_response(conn, 200) == %{
             "data" => %{
               "allowed_mentions" => %{"parse" => []},
               "embeds" => [
                 %{"color" => color_error(), "description" => "通貨が見つかりませんでした。", "title" => "エラー"}
               ],
               "flags" => 64
             },
             "type" => 4
           }
  end

  test "info by name", %{conn: conn, unit: unit, name: name} = ctx do
    conn =
      post_command(
        conn,
        from_guild_name(name, ctx.user1, -1)
      )

    assert json_response(conn, 200) == %{
             "data" => %{
               "embeds" => [
                 %{
                   "author" => nil,
                   "color" => color_brand(),
                   "fields" => [
                     %{"inline" => true, "name" => "総発行量", "value" => "`200500#{unit}`"},
                     %{"inline" => true, "name" => "発行枠", "value" => "`500#{unit}`"},
                     %{"inline" => true, "name" => "あなたの所持量", "value" => "`199500#{unit}`"}
                   ],
                   "footer" => %{"text" => "発行枠は一日一回総発行量の0.5%増加し、最大で総発行量の3.5%となります。"},
                   "title" => name
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           }
  end

  test "info by name error", %{conn: conn} = ctx do
    conn =
      post_command(
        conn,
        from_guild_name("fuwafuwa", ctx.user1, -1)
      )

    assert json_response(conn, 200) == %{
             "data" => %{
               "allowed_mentions" => %{"parse" => []},
               "embeds" => [
                 %{"color" => color_error(), "description" => "通貨が見つかりませんでした。", "title" => "エラー"}
               ],
               "flags" => 64
             },
             "type" => 4
           }
  end
end
