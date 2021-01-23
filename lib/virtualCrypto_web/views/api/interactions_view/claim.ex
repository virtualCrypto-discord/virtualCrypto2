defmodule VirtualCryptoWeb.Api.InteractionsView.Claim do
  def render_error(:not_found) do
    "そのidの請求は見つかりませんでした。"
  end

  def render_error(:not_enough_amount) do
    "お金が足りません。"
  end

  def render_error(:money_not_found) do
    "指定された通貨は存在しません。"
  end

  def render_sent_claim(sent_claims) do
    sent_claims
    |> Enum.map(fn claim ->
      money = VirtualCrypto.Money.InternalAction.get_money_by_id(claim.money_info_id)
      payer_user = VirtualCrypto.User.get_user_by_id(claim.payer_user_id)

      ~s/id: #{claim.id}, 請求先: <@#{payer_user.discord_id}>, 請求額: #{claim.amount}#{money.unit}, 請求日: #{
        claim.inserted_at
      }/
    end)
    |> Enum.join("\n")
  end

  def render_received_claim(received_claims) do
    received_claims
    |> Enum.map(fn claim ->
      money = VirtualCrypto.Money.InternalAction.get_money_by_id(claim.money_info_id)
      claim_user = VirtualCrypto.User.get_user_by_id(claim.claimant_user_id)

      ~s/id: #{claim.id}, 請求元: <@#{claim_user.discord_id}>, 請求額: #{claim.amount}#{money.unit}, 請求日: #{
        claim.inserted_at
      }/
    end)
    |> Enum.join("\n")
  end

  def render({:ok, "list", sent_claims, received_claims}) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content:
          ~s/友達への請求:\n#{render_sent_claim(sent_claims)}\n\n自分に来た請求:\n#{
            render_received_claim(received_claims)
          }/
      }
    }
  end

  def render({:ok, "make", claim}) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content: ~s/請求id: #{claim.id} で請求を受け付けました。`\/claim list`でご確認ください。/
      }
    }
  end

  def render({:ok, "approve", {claim, _, _, _}}) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content: ~s/id: #{claim.id}の請求を承諾し、支払いました。/
      }
    }
  end

  def render({:ok, "deny", {claim, _, _, _}}) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content: ~s/id: #{claim.id}の請求を拒否しました。/
      }
    }
  end

  def render({:ok, "cancel", {claim, _, _, _}}) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content: ~s/id: #{claim.id}の請求をキャンセルしました。/
      }
    }
  end

  def render({:error, _, error}) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content: ~s/エラー: #{render_error(error)}/
      }
    }
  end
end
