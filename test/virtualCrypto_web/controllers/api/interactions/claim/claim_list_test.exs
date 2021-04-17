defmodule InteractionsControllerTest.Claim.List do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Claim.Patch
  import VirtualCryptoWeb.Api.InteractionsView.Util, only: [format_date_time: 1]
  setup :setup_claim

  def generate_outgoing_claim_text({claim, currency, _claimant, payer}) do
    "id: #{claim.id}, 請求先: <@#{payer.discord_id}>, 請求額: **#{claim.amount}** `#{currency.unit}`, 請求日: #{
      format_date_time(claim.inserted_at)
    }"
  end

  def generate_incoming_claim_text({claim, currency, claimant, _payer}) do
    "id: #{claim.id}, 請求元: <@#{claimant.discord_id}>, 請求額: **#{claim.amount}** `#{currency.unit}`, 請求日: #{
      format_date_time(claim.inserted_at)
    }"
  end

  test "list nothing", %{conn: conn} do
    conn =
      post_command(
        conn,
        list_from_guild(-1)
      )

    assert_discord_message(conn, "友達への請求:\n\n\n自分に来た請求:\n")
  end

  test "list user1", %{conn: conn, user1: user1} do
    conn =
      post_command(
        conn,
        list_from_guild(user1)
      )

    assert %{
             "data" => %{"content" => content, "flags" => 64},
             "type" => 4
           } = json_response(conn, 200)

    regex = ~r/友達への請求:\n(.*)\n\n自分に来た請求:\n(.*)/us
    assert [_, outgoing, incoming] = Regex.run(regex, content)
    claims = VirtualCrypto.Money.get_claims(VirtualCrypto.Money.DiscordService, user1, "pending")

    outgoing_claims =
      claims
      |> Enum.filter(fn
        {_claim, _money, %{discord_id: ^user1}, _payer} -> true
        _ -> false
      end)
      |> Enum.sort(&(elem(&1, 0).id <= elem(&2, 0).id))
      |> Enum.map(&generate_outgoing_claim_text(&1))
      |> Enum.join("\n")

    incoming_claims =
      claims
      |> Enum.filter(fn
        {_claim, _money, _claimant, %{discord_id: ^user1}} -> true
        _ -> false
      end)
      |> Enum.sort(&(elem(&1, 0).id <= elem(&2, 0).id))
      |> Enum.map(&generate_incoming_claim_text(&1))
      |> Enum.join("\n")

    assert outgoing == outgoing_claims
    assert incoming == incoming_claims
  end
end
