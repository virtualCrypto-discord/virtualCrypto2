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
    description = "[Botの招待](#{bot_invite_url})\n[サポートサーバーの招待](#{support_guild_invite_url})"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "title" => "VirtualCrypto",
                   "color" => ^color,
                   "thumbnail" => %{
                     "url" => "https://vcrypto.sumidora.com/static/images/logo.jpg"
                   },
                   "description" => ^description
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end
end
