defmodule InteractionsControllerTest.Info do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Info.Helper
  import VirtualCryptoWeb.Api.InteractionsView.Util

  @option_required %{
    "data" => %{
      "embeds" => [
        %{
          "color" => color_error(),
          "title" => "エラー",
          "description" => "オプションを指定する必要があります。"
        }
      ],
      "flags" => 64,
      "allowed_mentions" => %{"parse" => []}
    },
    "type" => 4
  }

  setup :setup_money

  describe "normal" do

    test "info in guild", %{conn: conn, guild: guild, unit: unit, name: name} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild(ctx.user1, guild)
        )

      assert json_response(conn, 200) == @option_required
    end

    test "info in guild not hold", %{conn: conn, guild: guild, unit: unit, name: name} do
      conn =
        execute_interaction(
          conn,
          from_guild(-1, guild)
        )

      assert json_response(conn, 200) == @option_required
    end

    test "info in guild error", %{conn: conn} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild(ctx.user1, -1)
        )

      assert json_response(conn, 200) == @option_required
    end

    test "info by unit", %{conn: conn, unit: unit, name: name} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild_unit(unit, ctx.user1, -1)
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "embeds" => [
                   %{
                     "color" => color_brand(),
                     "fields" => [
                       %{"inline" => true, "name" => "総発行量", "value" => "`200500#{unit}`"},
                       %{"inline" => true, "name" => "あなたの所持量", "value" => "`199500#{unit}`"}
                     ],
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
        execute_interaction(
          conn,
          from_guild_unit("gao", ctx.user1, -1)
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "allowed_mentions" => %{"parse" => []},
                 "embeds" => [
                   %{
                     "color" => color_error(),
                     "description" => "通貨が見つかりませんでした。",
                     "title" => "エラー"
                   }
                 ],
                 "flags" => 64
               },
               "type" => 4
             }
    end

    test "info by unit not hold", %{conn: conn} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild_unit(ctx.unit, -21, -1)
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "embeds" => [
                   %{
                     "color" => color_brand(),
                     "fields" => [
                       %{"inline" => true, "name" => "総発行量", "value" => "`200500#{ctx.unit}`"},
                       %{"inline" => true, "name" => "あなたの所持量", "value" => "`0#{ctx.unit}`"}
                     ],
                     "title" => ctx.name
                   }
                 ],
                 "flags" => 64
               },
               "type" => 4
             }
    end

    test "info by name", %{conn: conn, unit: unit, name: name} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild_name(name, ctx.user1, -1)
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "embeds" => [
                   %{
                     "color" => color_brand(),
                     "fields" => [
                       %{"inline" => true, "name" => "総発行量", "value" => "`200500#{unit}`"},
                       %{"inline" => true, "name" => "あなたの所持量", "value" => "`199500#{unit}`"}
                     ],
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
        execute_interaction(
          conn,
          from_guild_name("fuwafuwa", ctx.user1, -1)
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "allowed_mentions" => %{"parse" => []},
                 "embeds" => [
                   %{
                     "color" => color_error(),
                     "description" => "通貨が見つかりませんでした。",
                     "title" => "エラー"
                   }
                 ],
                 "flags" => 64
               },
               "type" => 4
             }
    end

    test "info by name not hold", %{conn: conn, unit: unit, name: name} do
      conn =
        execute_interaction(
          conn,
          from_guild_name(name, -1, -1)
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "embeds" => [
                   %{
                     "color" => color_brand(),
                     "fields" => [
                       %{"inline" => true, "name" => "総発行量", "value" => "`200500#{unit}`"},
                       %{"inline" => true, "name" => "あなたの所持量", "value" => "`0#{unit}`"}
                     ],
                     "title" => name
                   }
                 ],
                 "flags" => 64
               },
               "type" => 4
             }
    end

    test "run in dm", %{conn: conn} = ctx do
      conn =
        execute_interaction(
          conn,
          from_dm(ctx.user1)
        )

      assert json_response(conn, 200) == @option_required
    end
  end
end
