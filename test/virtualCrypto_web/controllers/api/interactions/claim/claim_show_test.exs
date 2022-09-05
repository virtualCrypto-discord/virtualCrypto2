defmodule InteractionsControllerTest.Claim.Show do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Claim.Helper
  import InteractionsControllerTest.Helper.Common
  import VirtualCryptoWeb.Api.InteractionsView.Util
  setup :setup_claim

  def show_from_guild(user, id) do
    execute_from_guild(
      %{
        name: "claim",
        options: [
          %{
            name: "show",
            options: [
              %{
                name: "id",
                value: id
              }
            ]
          }
        ]
      },
      user
    )
  end

  test "show nothing", %{conn: conn, user1: user1} do
    conn =
      execute_interaction(
        conn,
        show_from_guild(user1, -1)
      )

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => color_error(),
                   "description" => "そのidの請求は見つかりませんでした。",
                   "title" => "エラー"
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           } == json_response(conn, 200)
  end

  test "show unrelated claim", %{conn: conn, user2: user, claims: claims} do
    conn =
      execute_interaction(
        conn,
        show_from_guild(user, (claims |> Enum.at(5)).claim.id)
      )

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => color_error(),
                   "description" => "そのidの請求は見つかりませんでした。",
                   "title" => "エラー"
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           } == json_response(conn, 200)
  end

  test "show related claim", %{conn: conn, user1: user, claims: claims} do
    conn =
      execute_interaction(
        conn,
        show_from_guild(user, (claims |> Enum.at(5)).claim.id)
      )

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => color_error(),
                   "description" => "そのidの請求は見つかりませんでした。",
                   "title" => "エラー"
                 }
               ],
               "flags" => 64
             },
             "type" => 4
           } == json_response(conn, 200)
  end

end
