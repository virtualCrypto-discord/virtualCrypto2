defmodule VirtualCryptoWeb.InteractionsView.Pay do
  import VirtualCryptoWeb.InteractionsView.Util
  defp render_error(:not_found_money) do
    "エラー: 通貨は存在しません。"
  end
  defp render_error(:not_found_sender_asset) do
    "エラー: 通貨を持っていません。"
  end
  defp render_error(:not_enough_amount)do
    "エラー: 通貨が不足しています。"
  end
  
  def render(:ok, %{unit: unit, receiver: receiver, sender: sender, amount: amount}) do
    %{
      type: 3,
      data: %{
        embeds: [
          %{
            "description" =>
              mention(sender) <>
                "から" <>
                mention(receiver) <> "へ" <> Integer.to_string(amount) <> unit <> "送金されました。",
            color: 0x38EA42
          }
        ],
        allowed_mentions: []
      }
    }
  end

  def render(:error, err) do
    %{
      type: 3,
      data: %{
        tts: false,
        flags: 64,
        content: render_error(err),
        embeds: [],
        allowed_mentions: []
      }
    }
  end
end
