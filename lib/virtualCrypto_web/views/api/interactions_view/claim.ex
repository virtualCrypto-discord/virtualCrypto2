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
    "不正な金額です。"
  end

  defp render_error(:not_found_sender_asset) do
    render_error(:not_enough_amount)
  end

  defp render_error(:invalid_operator) do
    "この請求に対してこの操作を行う権限がありません。"
  end

  defp render_sent_claim(sent_claims) do
    sent_claims
    |> Enum.map(fn {claim, money, _claimant, payer} ->
      ~s/id: #{claim.id}, 請求先: #{mention(payer.discord_id)}, 請求額: **#{claim.amount}** `#{
        money.unit
      }`, 請求日: #{format_date_time(claim.inserted_at)}/
    end)
    |> Enum.join("\n")
  end

  defp render_received_claim(received_claims) do
    received_claims
    |> Enum.map(fn {claim, money, claimant, _payer} ->
      ~s/id: #{claim.id}, 請求元: #{mention(claimant.discord_id)}, 請求額: **#{claim.amount}** `#{
        money.unit
      }`, 請求日: #{format_date_time(claim.inserted_at)}/
    end)
    |> Enum.join("\n")
  end

  def render({:ok, "list", sent_claims, received_claims}) do
    %{
      type: channel_message_with_source(),
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
