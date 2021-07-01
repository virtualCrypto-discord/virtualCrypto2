defmodule VirtualCryptoWeb.Api.InteractionsView.Claim.Listing do
  import VirtualCryptoWeb.Api.InteractionsView.Util

  defp render_title("received") do
    "請求一覧(received)"
  end

  defp render_title("sent") do
    "請求一覧(sent)"
  end

  defp render_title("list") do
    "請求一覧(all)"
  end

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

  defp render_user("received", claimant, _payer) do
    ["請求元: #{mention(claimant.discord_id)}"]
  end

  defp render_user("sent", _claimant, payer) do
    ["請求先: #{mention(payer.discord_id)}"]
  end

  defp render_user("list", claimant, payer) do
    ["請求元: #{mention(claimant.discord_id)}", "請求先: #{mention(payer.discord_id)}"]
  end

  defp render_claim(subcommand, claims, me) do
    claims
    |> Enum.map(fn %{claim: claim, currency: currency, claimant: claimant, payer: payer} ->
      %{
        name: render_claim_name(me, claimant.discord_id, payer.discord_id) <> to_string(claim.id),
        value:
          ([
             "状態　: #{render_status(claim.status)}",
             "請求額: **#{claim.amount}** `#{currency.unit}`"
           ] ++
             render_user(subcommand, claimant, payer) ++
             [
               "請求日: #{format_date_time(claim.inserted_at)}"
             ])
          |> Enum.join("\n")
      }
    end)
  end

  defp custom_id(_subcommand, nil, _flags) do
    "disabled"
  end

  defp custom_id(subcommand, :last, query) do
    "claim/#{subcommand}/last?#{query}"
  end

  defp custom_id(subcommand, n, query) do
    "claim/#{subcommand}/#{n}?#{query}"
  end

  defp disabled(nil) do
    true
  end

  defp disabled(_) do
    false
  end

  defp page(subcommand, claims, me) do
    %{
      title: render_title(subcommand),
      color: color_brand(),
      fields: render_claim(subcommand, claims, me),
      description:
        case claims do
          [] -> "表示する内容がありません。"
          _ -> nil
        end
    }
  end

  defp pagination_row(subcommand, %{
         first: first,
         last: last,
         prev: prev,
         next: next,
         page: page,
         query: query
       }) do
    query = URI.encode_query(query)

    %{
      type: action_row(),
      components: [
        %{
          type: button(),
          style: button_style_secondary(),
          emoji: %{name: "⏪"},
          custom_id: custom_id(subcommand, first, query),
          disabled: disabled(first)
        },
        %{
          type: button(),
          style: button_style_secondary(),
          emoji: %{name: "⏮️"},
          custom_id: custom_id(subcommand, prev, query),
          disabled: disabled(prev)
        },
        %{
          type: button(),
          style: button_style_secondary(),
          emoji: %{name: "⏭️"},
          custom_id: custom_id(subcommand, next, query),
          disabled: disabled(next)
        },
        %{
          type: button(),
          style: button_style_secondary(),
          emoji: %{name: "⏩"},
          custom_id: custom_id(subcommand, last, query),
          disabled: disabled(last)
        },
        %{
          type: button(),
          style: button_style_secondary(),
          custom_id: custom_id(subcommand, page, query),
          emoji: %{name: "🔄"}
        }
      ]
    }
  end

  def render(
        subcommand,
        %{
          type: typ,
          claims: claims,
          me: me
        } = m
      )
      when subcommand in ["list", "received", "sent"] do
    typ =
      case typ do
        :command -> channel_message_with_source()
        :button -> update_message()
      end

    %{
      type: typ,
      data: %{
        flags: ephemeral(),
        embeds: [page(subcommand, claims, me)],
        components: [
          pagination_row(subcommand, m)
        ]
      }
    }
  end
end
