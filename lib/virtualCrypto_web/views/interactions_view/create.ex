defmodule VirtualCryptoWeb.InteractionsView.Create do
  import VirtualCryptoWeb.InteractionsView.Util

  defp render_error :guild, _ do
    "このギルドではすでに通貨が作成されています。"
  end

  defp render_error :name, options do
    options["name"] <> "という単位の通貨は存在しています。別の名前を使用してください。"
  end

  defp render_error :unit, options do
    options["unit"] <> "という単位の通貨は存在しています。別の名前を使用してください。"
  end

  defp render_error :invalid, _ do
    "通貨の名前は2から16文字以内の英数字、単位は1から10文字以内の英小文字を使ってください。"
  end

  defp render_error :permission, _ do
    "実行には管理者権限が必要です。"
  end

  defp render_error _, _ do
    "不明なエラーが発生しました。時間を開けてもう一度実行してください。"
  end

  def render(:ok, :ok, options) do
    %{
      type: 4,
      data: %{
        embeds: [
          %{
            description: ~s"\u2705 通貨の作成に成功しました！ `/info unit: #{options["unit"]}`コマンドで通貨の情報をご覧ください。",
            color: 0x38EA42
          }
        ],
        allowed_mentions: []
      }
    }
  end

  def render(:error, reason, options) do
    %{
      type: 3,
      data: %{
        tts: false,
        flags: 64,
        content: "エラー: " <> render_error(reason, options),
        embeds: [],
        allowed_mentions: []
      }
    }
  end

end
