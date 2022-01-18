defmodule VirtualCryptoWeb.Api.InteractionsView.Claim do
  import VirtualCryptoWeb.Api.InteractionsView.Util
  import VirtualCryptoWeb.Api.InteractionsView.Claim.Common
  alias VirtualCryptoWeb.Api.InteractionsView.Claim.Show

  defp render_error(:not_found) do
    "そのidの請求は見つかりませんでした。"
  end

  defp render_error(:not_enough_amount) do
    "お金が足りません。"
  end

  defp render_error(:not_found_currency) do
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

  def render({:ok, subcommand, m})
      when subcommand in [:all, :received, :claimed, :select] do
    VirtualCryptoWeb.Api.InteractionsView.Claim.Listing.render(subcommand, m)
  end

  def render({:ok, "make", claim}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            description: "請求id: #{claim.id} で請求を受け付けました。`\/claim show id:#{claim.id}`でご確認ください。",
            color: color_ok()
          }
        ]
      }
    }
  end

  def render({:ok, "approve", claim}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            description: render_action_result(:approve, claim),
            color: color_ok()
          }
        ]
      }
    }
  end

  def render({:ok, "deny", claim}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            description: render_action_result(:deny, claim),
            color: color_ok()
          }
        ]
      }
    }
  end

  def render({:ok, "cancel", claim}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            description: render_action_result(:cancel, claim),
            color: color_ok()
          }
        ]
      }
    }
  end

  def render({:ok, "show", data}) do
    Show.render(data)
  end

  def render({:error, _, error}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            title: "エラー",
            description: "#{render_error(error)}",
            color: color_error()
          }
        ]
      }
    }
  end
end
