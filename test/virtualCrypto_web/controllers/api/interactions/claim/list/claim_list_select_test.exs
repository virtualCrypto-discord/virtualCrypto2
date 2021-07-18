defmodule InteractionsControllerTest.Claim.List.Select do
  use VirtualCryptoWeb.InteractionsCase, async: true
  alias VirtualCryptoWeb.Interaction.CustomId
  alias VirtualCryptoWeb.Interaction.CustomId.UI.Button
  alias VirtualCryptoWeb.Interaction.CustomId.UI.SelectMenu
  alias VirtualCryptoWeb.Interaction.Claim.List.Options, as: ListOptions
  alias VirtualCryptoWeb.Interaction.Claim.List.Helper
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  import InteractionsControllerTest.Helper.Common
  import InteractionsControllerTest.Claim.Helper
  import VirtualCryptoWeb.Api.InteractionsView.Util

  setup :setup_claim

  defp render_claim(me, %{claim: claim, claimant: claimant, payer: payer, currency: currency}) do
    %{
      "name" =>
        "☑" <>
          render_claim_name(me, claimant.discord_id, payer.discord_id) <> to_string(claim.id),
      "value" =>
        [
          "状態　: ⌛未決定",
          "請求額: **#{claim.amount}** `#{currency.unit}`",
          "請求元: <@#{claimant.discord_id}>",
          "請求先: <@#{payer.discord_id}>",
          "請求日: #{format_date_time(claim.inserted_at)}"
        ]
        |> Enum.join("\n")
    }
  end

  test "selection", %{conn: conn, user1: user1, name: name, unit: unit} do
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

    options = %ListOptions{
      approved: false,
      canceled: false,
      denied: false,
      pending: true,
      page: 1,
      position: :all,
      related_user: 0
    }

    encoded_claims_ids = Helper.encode_claim_ids(claims.claims)

    custom_id_select =
      CustomId.encode(
        SelectMenu.claim_select() <>
          ListOptions.encode(options) <> encoded_claims_ids
      )

    conn =
      execute_interaction(
        conn,
        select_from_guild(
          %{
            custom_id: custom_id_select,
            values: claims.claims |> Enum.map(&to_string(&1.claim.id))
          },
          user1
        )
      )

    select_menu_options =
      claims.claims
      |> Enum.map(fn %{claim: claim, claimant: claimant, payer: payer} ->
        %{
          "default" => true,
          "description" => "#{claim.amount} #{unit}",
          "label" =>
            render_claim_name(user1, claimant.discord_id, payer.discord_id) <> "#{claim.id}",
          "value" => "#{claim.id}"
        }
      end)

    total_selected_amount =
      claims.claims
      |> Enum.map(fn %{claim: claim, payer: payer} ->
        if payer.discord_id == user1, do: claim.amount, else: 0
      end)
      |> Enum.sum()

    action_buttons =
      [
        %{
          "custom_id" => :back,
          "emoji" => "⬅️",
          "style" => 2
        },
        %{
          "custom_id" => :approve,
          "emoji" => "✅",
          "style" => 3,
          "disabled" => true
        },
        %{
          "custom_id" => :deny,
          "emoji" => "❌",
          "style" => 4,
          "disabled" => true
        },
        %{
          "custom_id" => :cancel,
          "emoji" => "🗑️",
          "style" => 1,
          "disabled" => true
        }
      ]
      |> Enum.map(
        &Map.merge(&1, %{
          "custom_id" =>
            CustomId.encode(
              Button.claim_action(&1["custom_id"]) <>
                ListOptions.encode(options) <> encoded_claims_ids
            ),
          "emoji" => %{"name" => &1["emoji"]},
          "type" => 2
        })
      )

    assert total_selected_amount == 10_000_099
    res = json_response(conn, 200)

    d = %{
      "data" => %{
        "components" => [
          %{
            "components" => [
              %{
                "custom_id" => custom_id_select,
                "max_values" => 3,
                "min_values" => 0,
                "type" => select_menu(),
                "options" => select_menu_options
              }
            ],
            "type" => action_row()
          },
          %{
            "components" => action_buttons,
            "type" => action_row()
          }
        ],
        "embeds" => [
          %{
            "color" => color_brand(),
            "title" => "請求一覧(all)",
            "description" => nil,
            "fields" => claims.claims |> Enum.map(fn claim -> render_claim(user1, claim) end)
          },
          %{
            "color" => color_brand(),
            "title" => "残高",
            "description" =>
              "**#{name}**: `200000#{unit}` - `10000099#{unit}` => `-9800099#{unit}`⚠"
          }
        ],
        "flags" => ephemeral()
      },
      # update source message
      "type" => update_message()
    }

    assert res == d
  end

  test "illegal selection", %{conn: conn, user1: user1, user2: user2} do
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

    options = %ListOptions{
      approved: false,
      canceled: false,
      denied: false,
      pending: true,
      page: 1,
      position: :all,
      related_user: 0
    }

    encoded_claims_ids = Helper.encode_claim_ids(claims.claims)

    custom_id_select =
      CustomId.encode(
        SelectMenu.claim_select() <>
          ListOptions.encode(options) <> encoded_claims_ids
      )

    assert_raise(ArgumentError, "Illegal request", fn ->
      execute_interaction(
        conn,
        select_from_guild(
          %{
            custom_id: custom_id_select,
            values: claims.claims |> Enum.map(&to_string(&1.claim.id))
          },
          user2
        )
      )
    end)
  end
end
