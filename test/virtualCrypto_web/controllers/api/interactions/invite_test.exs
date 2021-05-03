defmodule InteractionsControllerTest.Invite do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Helper.Common
  import VirtualCryptoWeb.Api.InteractionsView.Util
  test "invite", %{conn: conn} do
    conn =
      post_command(
        conn,
        execute_from_guild(
          %{
            name: "invite"
          },
          12
        )
      )
    color = color_brand()
    bot_invite_url = Application.get_env(:virtualCrypto, :invite_url)
    support_guild_invite_url = Application.get_env(:virtualCrypto, :support_guild_invite_url)
    assert %{
             "data" => %{
               "embeds" => [%{
                 "color" => ^color,
                 "fields" => [
                   %{
                     "name" => "ボット",
                     "value" => ^bot_invite_url
                   },
                   %{
                    "name" => "サポートサーバー",
                    "value" => ^support_guild_invite_url
                  }
                 ]
               }],
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)

  end
end
