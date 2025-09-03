defmodule InteractionsControllerTest.Claim.Show do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Helper.Common
  import VirtualCryptoWeb.Api.Interactions.Util
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

  test "show related claim", %{
    conn: conn,
    user1: user,
    claims: claims,
    unit: unit,
    name: currency_name
  } do
    claim = (claims |> Enum.at(5)).claim
    claim_id = claim.id

    conn =
      execute_interaction(
        conn,
        show_from_guild(user, claim_id)
      )

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => 6_431_213,
                   "title" => "請求",
                   "fields" => [
                     %{
                       "name" => name,
                       "value" => value
                     }
                   ]
                 },
                 %{
                   "color" => 6_431_213,
                   "description" => desc,
                   "title" => "残高"
                 }
               ],
               "flags" => 64,
               "components" => [
                 %{
                   "components" => [
                     %{
                       "disabled" => false,
                       "emoji" => %{"name" => "✅"},
                       "style" => 3,
                       "type" => 2
                     },
                     %{
                       "disabled" => false,
                       "emoji" => %{"name" => "❌"},
                       "style" => 4,
                       "type" => 2
                     },
                     %{
                       "disabled" => false,
                       "emoji" => %{"name" => "🗑️"},
                       "style" => 1,
                       "type" => 2
                     }
                   ],
                   "type" => 1
                 }
               ],
               "content" => ""
             },
             "type" => 4
           } = json_response(conn, 200)

    assert name == "📤📥#{claim_id}"

    assert value ==
             "状態　: ⌛未決定\n請求額: **100** `#{unit}`\n請求元: <@#{user}>\n請求先: <@#{user}>\n請求日: <t:#{claim.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:second)}>"

    assert desc == "**#{currency_name}**: `200000#{unit}` - `100#{unit}` => `199900#{unit}`"
  end
end
