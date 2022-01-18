defmodule VirtualCryptoWeb.Api.InteractionsView.Claim.Show do
  import VirtualCryptoWeb.Api.InteractionsView.Util
  import VirtualCryptoWeb.Api.InteractionsView.Claim.Common
  alias VirtualCryptoWeb.Interaction.CustomId

  defp action_custom_id(k, action, claim) do
    CustomId.encode(
      k,
      CustomId.UI.Button.claim_action_single(action) <> <<claim.id::64>>
    )
  end

  defp selection_execute_row(k, %{
         claim: %{amount: amount} = claim,
         claimant: claimant,
         payer: payer,
         current: current,
         me: me
       }) do
    [
      %{
        type: button(),
        style: button_style_success(),
        emoji: %{name: "✅"},
        custom_id: action_custom_id(k + 1, :approve, claim),
        disabled: me != payer.discord_id or amount > current
      },
      %{
        type: button(),
        style: button_style_danger(),
        emoji: %{name: "❌"},
        custom_id: action_custom_id(k + 2, :deny, claim),
        disabled: me != payer.discord_id
      },
      %{
        type: button(),
        style: button_style_primary(),
        emoji: %{name: "🗑️"},
        custom_id: action_custom_id(k + 3, :cancel, claim),
        disabled: me != claimant.discord_id
      }
    ]
  end

  defp render_rs_icon(me, claimant_discord_id, payer_discord_id)
       when me == claimant_discord_id and me == payer_discord_id do
    "📤📥"
  end

  defp render_rs_icon(me, claimant_discord_id, _payer_discord_id)
       when me == claimant_discord_id do
    "📤"
  end

  defp render_rs_icon(me, _claimant_discord_id, payer_discord_id)
       when me == payer_discord_id do
    "📥"
  end

  defp render_user(claimant, payer) do
    ["請求元: #{mention(claimant.discord_id)}", "請求先: #{mention(payer.discord_id)}"]
  end

  defp render_status("approved") do
    "✅支払い済み"
  end

  defp render_status("denied") do
    "❌拒否"
  end

  defp render_status("canceled") do
    "🗑️キャンセル"
  end

  defp render_status("pending") do
    "⌛未決定"
  end

  defp render_quotation(%{currency: currency, current: current, quoted: quoted}) do
    u = currency.unit
    warn = if current < quoted, do: "⚠", else: ""

    "**#{currency.name}**: `#{current}#{u}` - `#{quoted}#{u}` => `#{current - quoted}#{u}`" <>
      warn
  end

  defp render_claim_field(%{
         claim: claim,
         claimant: claimant,
         payer: payer,
         currency: currency,
         me: me
       }) do
    %{
      name: render_rs_icon(me, claimant.discord_id, payer.discord_id) <> to_string(claim.id),
      value:
        ([
           "状態　: #{render_status(claim.status)}",
           "請求額: **#{claim.amount}** `#{currency.unit}`"
         ] ++
           render_user(claimant, payer) ++
           [
             "請求日: #{format_date_time(claim.inserted_at)}"
           ])
        |> Enum.join("\n")
    }
  end

  def depends_assets(%{
        assets: assets,
        currency: currency,
        claim: claim,
        claimant: claimant,
        payer: payer,
        me: me
      })
      when assets != nil do
    asset = assets |> Enum.find(fn asset -> asset.asset.currency_id == currency.id end)

    current =
      case asset do
        nil -> 0
        asset -> asset.asset.amount
      end

    quotation = [
      %{
        title: "残高",
        color: color_brand(),
        description:
          render_quotation(%{
            currency: currency,
            current: current,
            quoted: claim.amount
          })
      }
    ]

    components = [
      %{
        type: action_row(),
        components:
          selection_execute_row(0, %{
            claim: claim,
            claimant: claimant,
            payer: payer,
            me: me,
            current: current
          })
      }
    ]

    %{
      quotation: quotation,
      components: components
    }
  end

  def depends_assets(%{
        currency: currency,
        claim: %{status: "pending"} = claim,
        claimant: claimant,
        payer: payer,
        me: me
      }) do
    components = [
      %{
        type: action_row(),
        components:
          selection_execute_row(0, %{
            claim: claim,
            claimant: claimant,
            payer: payer,
            current: nil,
            me: me
          })
      }
    ]

    %{
      quotation: [],
      components: components
    }
  end

  def depends_assets(%{}) do
    %{
      quotation: [],
      components: []
    }
  end

  def render(
        %{
          claim: %{status: status} = claim,
          claimant: claimant,
          payer: payer,
          currency: currency,
          action: action,
          me: me
        } = data
      ) do
    claim_field =
      render_claim_field(%{
        claim: claim,
        claimant: claimant,
        payer: payer,
        currency: currency,
        me: me
      })

    %{components: components, quotation: quotation} =
      depends_assets(%{
        assets: Map.get(data, :assets),
        currency: currency,
        claim: claim,
        claimant: claimant,
        payer: payer,
        me: me
      })

    %{
      type:
        case action do
          :command -> channel_message_with_source()
          _ -> update_message()
        end,
      data: %{
        flags: 64,
        content:
          case action do
            :command -> ""
            _ -> render_action_result(action, claim)
          end,
        embeds:
          [
            %{
              title: "請求",
              fields: [claim_field],
              color: color_brand()
            }
          ] ++ quotation,
        components: components
      }
    }
  end
end
