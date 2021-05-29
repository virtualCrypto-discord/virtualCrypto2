defmodule VirtualCryptoWeb.Api.InteractionsView.Claim do
  import VirtualCryptoWeb.Api.InteractionsView.Util

  defp render_error(:not_found) do
    "そのidの請求は見つかりませんでした。"
  end

  defp render_error(:not_enough_amount) do
    "お金が足りません。"
  end

  defp render_error(:money_not_found) do
    "指定された通貨は存在しません。"
  end

  defp render_error(:invalid_amount) do
    "不正な金額です。1以上9223372036854775807以下である必要があります。"
  end

  defp render_error(:not_found_sender_asset) do
    render_error(:not_enough_amount)
  end

  defp render_error(:invalid_operator) do
    "この請求に対してこの操作を行う権限がありません。"
  end

  defp render_error(:invalid_status) do
    "この請求に対してこの操作を行うことは出来ません。"
  end

  defp render_claim_name(me, claimant_discord_id, payer_disocrd_id)
       when me == claimant_discord_id and me == payer_disocrd_id do
    "⬆⬇"
  end

  defp render_claim_name(me, claimant_discord_id, _payer_disocrd_id)
       when me == claimant_discord_id do
    "⬆"
  end

  defp render_claim_name(me, _claimant_discord_id, payer_disocrd_id)
       when me == payer_disocrd_id do
    "⬇"
  end

  defp render_claim(claims, me) do
    claims
    |> Enum.map(fn %{claim: claim, currency: currency, claimant: claimant, payer: payer} ->
      %{
        name: render_claim_name(me, claimant.discord_id, payer.discord_id) <> to_string(claim.id),
        value:
          ~s/請求元: #{mention(claimant.discord_id)} \n 請求先: #{mention(payer.discord_id)} \n 請求額: **#{
            claim.amount
          }** `#{currency.unit}`\n 請求日: #{format_date_time(claim.inserted_at)}/
      }
    end)
  end

  defp custom_id(nil) do
    "disabled"
  end

  defp custom_id(:last) do
    "claim/list/last"
  end

  defp custom_id(n) do
    "claim/list/#{n}"
  end

  defp disabled(nil) do
    true
  end

  defp disabled(_) do
    false
  end

  def render(
        {:ok, "list", %{type: typ,claims: claims, me: me, first: first, last: last, prev: prev, next: next,page: page}}
      ) do
    typ =  case typ do
      :command -> channel_message_with_source()
      :button -> 7
    end

    %{
      type: typ,
      data: %{
        flags: 64,
        embeds: [
          %{
            title: "請求一覧",
            color: color_brand(),
            fields: render_claim(claims, me)
          }
        ],
        components: [
          %{
            type: action_row(),
            components: [
              %{
                type: button(),
                style: button_style_secondary(),
                emoji: %{name: "⏪"},
                custom_id: custom_id(first),
                disabled: disabled(first)
              },
              %{
                type: button(),
                style: button_style_secondary(),
                emoji: %{name: "⏮️"},
                custom_id: custom_id(prev),
                disabled: disabled(prev)
              },
              %{
                type: button(),
                style: button_style_secondary(),
                emoji: %{name: "⏭️"},
                custom_id: custom_id(next),
                disabled: disabled(next)
              },
              %{
                type: button(),
                style: button_style_secondary(),
                emoji: %{name: "⏩"},
                custom_id: custom_id(last),
                disabled: disabled(last)
              },
              %{
                type: button(),
                style: button_style_secondary(),
                custom_id: custom_id(page),
                emoji: %{name: "🔄"},
              }
            ]
          }
        ]
      }
    }
  end

  def render({:ok, "make", claim}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: ~s/請求id: #{claim.id} で請求を受け付けました。`\/claim list`でご確認ください。/
      }
    }
  end

  def render({:ok, "approve", claim}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: ~s/id: #{claim.id}の請求を承諾し、支払いました。/
      }
    }
  end

  def render({:ok, "deny", claim}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: ~s/id: #{claim.id}の請求を拒否しました。/
      }
    }
  end

  def render({:ok, "cancel", claim}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: ~s/id: #{claim.id}の請求をキャンセルしました。/
      }
    }
  end

  def render({:error, _, error}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: ~s/エラー: #{render_error(error)}/
      }
    }
  end
end
