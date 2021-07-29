defmodule InteractionsControllerTest.Info do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Info.Helper
  import VirtualCryptoWeb.Api.InteractionsView.Util

  defmodule TestDiscordAPI do
    # @behaviour Discord.Api.Behavior

    def get_guild(guild_id) do
      %{"id" => to_string(guild_id), "name" => "TestGuild"}
    end
  end

  setup :setup_money

  describe "normal" do
    setup %{conn: conn} = d do
      Map.put(d, :conn, VirtualCryptoWeb.Plug.DiscordApiService.set_service(conn, TestDiscordAPI))
    end

    test "info in guild", %{conn: conn, guild: guild, unit: unit, name: name} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild(ctx.user1, guild)
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "embeds" => [
                   %{
                     "author" => %{"name" => "TestGuild"},
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
        execute_interaction(
          conn,
          from_guild(-1, guild)
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "embeds" => [
                   %{
                     "author" => %{"name" => "TestGuild"},
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
        execute_interaction(
          conn,
          from_guild(ctx.user1, -1)
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
                     "author" => %{"name" => "TestGuild"},
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
                     "author" => %{"name" => "TestGuild"},
                     "color" => color_brand(),
                     "fields" => [
                       %{"inline" => true, "name" => "総発行量", "value" => "`200500#{ctx.unit}`"},
                       %{"inline" => true, "name" => "発行枠", "value" => "`500#{ctx.unit}`"},
                       %{"inline" => true, "name" => "あなたの所持量", "value" => "`0#{ctx.unit}`"}
                     ],
                     "footer" => %{"text" => "発行枠は一日一回総発行量の0.5%増加し、最大で総発行量の3.5%となります。"},
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
                     "author" => %{"name" => "TestGuild"},
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
                     "author" => %{"name" => "TestGuild"},
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
  end

  describe "not has icon" do
    defmodule TestDiscordAPINotHasIcon do
      # @behaviour Discord.Api.Behavior

      def get_guild(guild_id) do
        %{"id" => to_string(guild_id), "name" => "TestGuild", "icon" => nil}
      end
    end

    setup %{conn: conn} = d do
      Map.put(
        d,
        :conn,
        VirtualCryptoWeb.Plug.DiscordApiService.set_service(conn, TestDiscordAPINotHasIcon)
      )
    end

    test "info by unit", %{conn: conn, unit: unit} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild_unit(unit, ctx.user1, -1)
        )

      assert %{"name" => "TestGuild"} ==
               (json_response(conn, 200)["data"]["embeds"] |> hd())["author"]
    end
  end

  describe "has icon" do
    defmodule TestDiscordAPIHasIcon do
      # @behaviour Discord.Api.Behavior

      def get_guild(guild_id) do
        %{
          "id" => to_string(guild_id),
          "name" => "TestGuild",
          "icon" => "981b65442cb7cffa5a60b6b94a10d263"
        }
      end
    end

    setup %{conn: conn} = d do
      Map.put(
        d,
        :conn,
        VirtualCryptoWeb.Plug.DiscordApiService.set_service(conn, TestDiscordAPIHasIcon)
      )
    end

    test "info by unit", %{conn: conn, unit: unit} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild_unit(unit, ctx.user1, -1)
        )

      assert %{
               "name" => "TestGuild",
               "icon_url" =>
                 "https://cdn.discordapp.com/icons/#{ctx.guild}/981b65442cb7cffa5a60b6b94a10d263.webp"
             } ==
               (json_response(conn, 200)["data"]["embeds"] |> hd())["author"]
    end
  end

  describe "has animated icon" do
    defmodule TestDiscordAPIHasAnimatedIcon do
      # @behaviour Discord.Api.Behavior

      def get_guild(guild_id) do
        %{
          "id" => to_string(guild_id),
          "name" => "TestGuild",
          "icon" => "a_981b65442cb7cffa5a60b6b94a10d263"
        }
      end
    end

    setup %{conn: conn} = d do
      Map.put(
        d,
        :conn,
        VirtualCryptoWeb.Plug.DiscordApiService.set_service(conn, TestDiscordAPIHasAnimatedIcon)
      )
    end

    test "info by unit", %{conn: conn, unit: unit} = ctx do
      conn =
        execute_interaction(
          conn,
          from_guild_unit(unit, ctx.user1, -1)
        )

      assert %{
               "name" => "TestGuild",
               "icon_url" =>
                 "https://cdn.discordapp.com/icons/#{ctx.guild}/a_981b65442cb7cffa5a60b6b94a10d263.gif"
             } ==
               (json_response(conn, 200)["data"]["embeds"] |> hd())["author"]
    end
  end
end
