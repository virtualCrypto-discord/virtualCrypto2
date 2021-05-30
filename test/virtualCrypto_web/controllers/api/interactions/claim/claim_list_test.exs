defmodule InteractionsControllerTest.Claim.List do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Claim.Helper

  import VirtualCryptoWeb.Api.InteractionsView.Util,
    only: [format_date_time: 1, color_brand: 0, mention: 1]

  setup :setup_claim

  defp render_claim_name(me, claimant_discord_id, payer_discord_id)
       when me == claimant_discord_id and me == payer_discord_id do
    "📤📥"
  end

  defp render_claim_name(me, claimant_discord_id, _payer_discord_id)
       when me == claimant_discord_id do
    "📤"
  end

  defp render_claim_name(me, _claimant_discord_id, payer_discord_id)
       when me == payer_discord_id do
    "📥"
  end

  def generate_claim_field(me) do
    fn %{claim: claim, currency: currency, claimant: claimant, payer: payer} ->
      %{
        "name" => "#{render_claim_name(me, claimant.discord_id, payer.discord_id)}#{claim.id}",
        "value" => """
        状態　: ⌛未決定
        請求額: **#{claim.amount}** `#{currency.unit}`
        請求元: #{mention(claimant.discord_id)}
        請求先: #{mention(payer.discord_id)}
        請求日: #{format_date_time(claim.inserted_at)}
        """
      }
    end
  end

  test "list nothing", %{conn: conn} do
    conn =
      post_command(
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
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏪"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏮️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏭️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏩"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "claim/list/1?flags=1",
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
                   "title" => "請求一覧"
                 }
               ]
             },
             "type" => 4
           } == json_response(conn, 200)
  end

  test "list user1", %{conn: conn, user1: user1} do
    conn =
      post_command(
        conn,
        list_from_guild(user1)
      )

    color = color_brand()

    assert %{
             "data" => %{
               "flags" => 64,
               "components" => [
                 %{
                   "components" => [
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏪"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏮️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏭️"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "disabled",
                       "disabled" => true,
                       "emoji" => %{"name" => "⏩"},
                       "style" => 2,
                       "type" => 2
                     },
                     %{
                       "custom_id" => "claim/list/1?flags=1",
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
                   "color" => ^color,
                   "fields" => fields,
                   "title" => "請求一覧"
                 }
               ]
             },
             "type" => 4
           } = json_response(conn, 200)

    claims =
      VirtualCrypto.Money.get_claims(
        VirtualCrypto.Money.DiscordService,
        user1,
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
