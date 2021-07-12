defmodule VirtualCryptoWeb.Api.InteractionsView.Claim.Listing do
  import VirtualCryptoWeb.Api.InteractionsView.Util
  alias VirtualCryptoWeb.Interaction.CustomId
  alias VirtualCryptoWeb.Interaction.Claim.List.Options

  defp render_title(:received) do
    "請求一覧(received)"
  end

  defp render_title(:sent) do
    "請求一覧(sent)"
  end

  defp render_title(:all) do
    "請求一覧(all)"
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

  defp render_selection("pending", true) do
    "☑"
  end

  defp render_selection("pending", false) do
    "◻️"
  end

  defp render_selection(_, false) do
    ""
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

  defp render_user(:received, claimant, _payer) do
    ["請求元: #{mention(claimant.discord_id)}"]
  end

  defp render_user(:sent, _claimant, payer) do
    ["請求先: #{mention(payer.discord_id)}"]
  end

  defp render_user(:all, claimant, payer) do
    ["請求元: #{mention(claimant.discord_id)}", "請求先: #{mention(payer.discord_id)}"]
  end

  defp render_claim_name(
         %{
           claim: %{status: status} = claim,
           claimant: claimant,
           payer: payer,
           selected: selected
         },
         me
       ) do
    render_selection(status, selected) <>
      render_rs_icon(me, claimant.discord_id, payer.discord_id) <> to_string(claim.id)
  end

  defp render_claim(subcommand, claims, me) do
    claims
    |> Enum.map(fn %{
                     claim: claim,
                     currency: currency,
                     claimant: claimant,
                     payer: payer
                   } = m ->
      %{
        name: render_claim_name(m, me),
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

  defp join_bytes(enum) do
    Enum.reduce(enum, <<>>, fn elem, acc -> acc <> elem end)
  end

  defp encode_claims(claims) do
    claim_count = claims |> Enum.count()
    <<claim_count::8>> <> (claims |> Enum.map(&<<&1.claim.id::64>>) |> join_bytes)
  end

  defp custom_id(_subcommand, nil, _flags) do
    "disabled"
  end

  defp custom_id(subcommand, :last, query) do
    CustomId.encode(CustomId.UI.Button.claim_list(subcommand) <> Options.encode(%{query|page: :last}))
  end

  defp custom_id(subcommand, n, query) do
    CustomId.encode(CustomId.UI.Button.claim_list(subcommand) <> Options.encode(%{query|page: n}))
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
         options: options
       }) do
    %{
      type: action_row(),
      components: [
        %{
          type: button(),
          style: button_style_secondary(),
          emoji: %{name: "⏪"},
          custom_id: custom_id(subcommand, first, options),
          disabled: disabled(first)
        },
        %{
          type: button(),
          style: button_style_secondary(),
          emoji: %{name: "⏮️"},
          custom_id: custom_id(subcommand, prev, options),
          disabled: disabled(prev)
        },
        %{
          type: button(),
          style: button_style_secondary(),
          emoji: %{name: "⏭️"},
          custom_id: custom_id(subcommand, next, options),
          disabled: disabled(next)
        },
        %{
          type: button(),
          style: button_style_secondary(),
          emoji: %{name: "⏩"},
          custom_id: custom_id(subcommand, last, options),
          disabled: disabled(last)
        },
        %{
          type: button(),
          style: button_style_secondary(),
          custom_id: custom_id(subcommand, page, options),
          emoji: %{name: "🔄"}
        }
      ]
    }
  end

  defp selection_select_row(_subcommand, [], _me, _query) do
    []
  end

  defp selection_select_row(subcommand, claims, me, options) do
    [
      %{
        type: action_row(),
        components: [
          %{
            type: select_menu(),
            custom_id:
              CustomId.encode(
                CustomId.UI.SelectMenu.claim_select() <>
                  Options.encode(options) <>
                  encode_claims(claims)
              ),
            max_values: claims |> Enum.count(),
            min_values: 0,
            options: claims |> Enum.map(&render_select_option(subcommand, &1, me))
          }
        ]
      }
    ]
  end

  defp render_select_option(
         _subcommand,
         %{
           claim: claim,
           currency: currency,
           claimant: claimant,
           payer: payer,
           selected: selected
         },
         me
       ) do
    %{
      label:
        render_rs_icon(me, claimant.discord_id, payer.discord_id) <>
          to_string(claim.id),
      value: claim.id |> to_string,
      description: "#{claim.amount} #{currency.unit}",
      default: selected
    }
  end

  defp action_custom_id(action, claims, options) do
    CustomId.encode(
      CustomId.UI.Button.claim_action(action) <>
        Options.encode(options) <>
        encode_claims(claims)
    )
  end

  defp selection_execute_row([], _quotations, _me, _query) do
    []
  end

  defp selection_execute_row(selected_claims, quotations, me, query) do
    cancelable =
      selected_claims |> Enum.all?(fn %{claimant: claimant} -> claimant.discord_id == me end)

    deniable = selected_claims |> Enum.all?(fn %{payer: payer} -> payer.discord_id == me end)
    approvable = deniable and quotations |> Enum.all?(&(&1.current >= &1.quoted))

    [
      %{
        type: action_row(),
        components: [
          %{
            type: button(),
            style: button_style_secondary(),
            emoji: %{name: "⬅️"},
            custom_id: action_custom_id(:back, selected_claims, query)
          },
          %{
            type: button(),
            style: button_style_success(),
            emoji: %{name: "✅"},
            custom_id: action_custom_id(:approve, selected_claims, query),
            disabled: not approvable
          },
          %{
            type: button(),
            style: button_style_danger(),
            emoji: %{name: "❌"},
            custom_id: action_custom_id(:deny, selected_claims, query),
            disabled: not deniable
          },
          %{
            type: button(),
            style: button_style_primary(),
            emoji: %{name: "🗑️"},
            custom_id: action_custom_id(:cancel, selected_claims, query),
            disabled: not cancelable
          }
        ]
      }
    ]
  end

  defp render_quotation(%{currency: currency, current: current, quoted: 0}) do
    u = currency.unit
    "**#{currency.name}**: `#{current}#{u}`"
  end

  defp render_quotation(%{currency: currency, current: current, quoted: quoted}) do
    u = currency.unit
    warn = if current < quoted, do: "⚠", else: ""

    "**#{currency.name}**: `#{current}#{u}` - `#{quoted}#{u}` => `#{current - quoted}#{u}`" <>
      warn
  end

  defp selected_claim_embed([]) do
    []
  end

  defp selected_claim_embed(quotations) do
    [
      %{
        title: "残高",
        color: color_brand(),
        description:
          quotations
          |> Enum.map(&render_quotation/1)
          |> Enum.join("\n")
      }
    ]
  end

  def render(
        subcommand,
        %{
          type: typ,
          claims: claims,
          options: options,
          me: me
        } = m
      )
      when subcommand in [:all, :received, :claimed] do
    typ =
      case typ do
        :command -> channel_message_with_source()
        :button -> update_message()
      end

    pending_claims =
      claims |> Enum.filter(fn %{claim: %{status: status}} -> status == "pending" end)

    selected_claims = pending_claims |> Enum.filter(fn %{selected: s} -> s end)

    %{
      type: typ,
      data: %{
        flags: ephemeral(),
        embeds: [
          page(subcommand, claims, me)
        ],
        components:
          [
            pagination_row(subcommand, m)
          ] ++
            selection_select_row(
              subcommand,
              pending_claims,
              me,
              options
            ) ++
            selection_execute_row(
              selected_claims,
              [],
              me,
              options
            )
      }
    }
  end

  def render(
        :select,
        %{
          claims: claims,
          assets: assets,
          options: options,
          me: me
        }
      ) do
    pending_claims =
      claims |> Enum.filter(fn %{claim: %{status: status}} -> status == "pending" end)

    selected_claims = pending_claims |> Enum.filter(fn %{selected: s} -> s end)
    position = options.position
    assets = assets |> Map.new(fn %{currency: %{id: id}} = v -> {id, v} end)
    grouped_claims = selected_claims |> Enum.group_by(fn %{currency: %{id: id}} -> id end)

    quotations =
      grouped_claims
      |> Enum.map(fn {k, v} ->
        %{currency: currency, asset: asset} = assets[k]

        quoted =
          v
          |> Enum.filter(fn %{payer: %{discord_id: discord_id}} ->
            discord_id == me
          end)
          |> Enum.map(fn %{claim: %{amount: amount}} -> amount end)
          |> Enum.sum()

        %{currency: currency, current: asset.amount, quoted: quoted}
      end)

    %{
      type: update_message(),
      data: %{
        flags: ephemeral(),
        embeds:
          [
            page(position, claims, me)
          ] ++ selected_claim_embed(quotations),
        components:
          selection_select_row(
            position,
            pending_claims,
            me,
            options
          ) ++
            selection_execute_row(
              selected_claims,
              quotations,
              me,
              options
            )
      }
    }
  end
end
