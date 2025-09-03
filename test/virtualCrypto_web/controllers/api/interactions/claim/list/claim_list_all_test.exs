defmodule InteractionsControllerTest.Claim.List.All do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Claim.Helper

  import VirtualCryptoWeb.Api.Interactions.Util,
    only: [format_date_time: 1, color_brand: 0, mention: 1]

  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCryptoWeb.Interaction.CustomId
  alias VirtualCryptoWeb.Interaction.CustomId.UI.Button
  alias VirtualCryptoWeb.Interaction.CustomId.UI.SelectMenu
  alias VirtualCryptoWeb.Interaction.Claim.List.Options, as: ListOptions
  alias VirtualCryptoWeb.Interaction.Claim.List.Helper

  setup :setup_claim

  def generate_claim_field(me) do
    fn %{claim: claim, currency: currency, claimant: claimant, payer: payer} ->
      %{
        "name" => "◻️#{render_claim_name(me, claimant.discord_id, payer.discord_id)}#{claim.id}",
        "value" =>
          [
            "状態　: ⌛未決定",
            "請求額: **#{claim.amount}** `#{currency.unit}`",
            "請求元: #{mention(claimant.discord_id)}",
            "請求先: #{mention(payer.discord_id)}",
            "請求日: #{format_date_time(claim.inserted_at)}"
          ]
          |> Enum.join("\n")
      }
    end
  end

  test "list nothing", %{conn: conn} do
    conn =
      execute_interaction(
        conn,
        list_from_guild(-1)
      )

    assert %{
             "data" => %{
               "flags" => 64,
               "components" => [
                 %{
                   "components" => [
                     %{
                       "custom_id" => "disabled-0",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏪"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled-1",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏮️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled-2",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏭️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled-3",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏩"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" =>
                         CustomId.encode(
                           4,
                           Button.claim_list(:all) <>
                             ListOptions.encode(%ListOptions{
                               approved: false,
                               canceled: false,
                               denied: false,
                               pending: true,
                               page: 1,
                               position: :all,
                               related_user: 0
                             })
                         ),
                       "emoji" => %{"name" => "🔄"},
                       "style" => 2,
                       "type" => 2
                     }
                   ],
                   "type" => 1
                 }
               ],
               "embeds" => [
                 %{
                   "color" => color_brand(),
                   "description" => "表示する内容がありません。",
                   "fields" => [],
                   "title" => "請求一覧(all)"
                 }
               ]
             },
             "type" => 4
           } == json_response(conn, 200)
  end

  test "list user1", %{conn: conn, user1: user1} do
    conn =
      execute_interaction(
        conn,
        list_from_guild(user1)
      )

    color = color_brand()

    custom_id_reload =
      CustomId.encode(
        4,
        Button.claim_list(:all) <>
          ListOptions.encode(%ListOptions{
            approved: false,
            canceled: false,
            denied: false,
            pending: true,
            page: 1,
            position: :all,
            related_user: 0
          })
      )

    claims =
      VirtualCrypto.Money.get_claims(
        %DiscordUser{id: user1},
        ["pending"],
        :all,
        nil,
        :desc_claim_id,
        %{page: 1},
        5
      )

    custom_id_select =
      CustomId.encode(
        5,
        SelectMenu.claim_select() <>
          ListOptions.encode(%ListOptions{
            approved: false,
            canceled: false,
            denied: false,
            pending: true,
            page: 1,
            position: :all,
            related_user: 0
          }) <> Helper.encode_claim_ids(claims.claims)
      )

    res = json_response(conn, 200)

    assert %{
             "data" => %{
               "flags" => 64,
               "components" => [
                 %{
                   "components" => [
                     %{
                       "custom_id" => "disabled-0",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏪"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled-1",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏮️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled-2",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏭️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled-3",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏩"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => ^custom_id_reload,
                       "emoji" => %{"name" => "🔄"},
                       "style" => 2,
                       "type" => 2
                     }
                   ],
                   "type" => 1
                 },
                 %{
                   "components" => [
                     %{
                       "custom_id" => ^custom_id_select,
                       "max_values" => 3,
                       "min_values" => 0,
                       "options" => [
                         %{
                           "default" => false
                         },
                         %{
                           "default" => false
                         },
                         %{
                           "default" => false
                         }
                       ],
                       "type" => 3
                     }
                   ],
                   "type" => 1
                 }
               ],
               "embeds" => [
                 %{
                   "color" => ^color,
                   "fields" => fields,
                   "title" => "請求一覧(all)"
                 }
               ]
             },
             "type" => 4
           } = res

    claims =
      VirtualCrypto.Money.get_claims(
        %DiscordUser{id: user1},
        ["pending"],
        :all,
        nil,
        :desc_claim_id,
        %{page: 1},
        5
      )

    assert fields == claims.claims |> Enum.map(generate_claim_field(user1))
  end
end
