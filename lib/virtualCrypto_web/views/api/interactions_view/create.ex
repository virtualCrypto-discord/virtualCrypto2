defmodule VirtualCryptoWeb.Api.InteractionsView.Create do
  import VirtualCryptoWeb.Api.InteractionsView.Util

  defp render_error(:duplicate_guild, _) do
    "このギルドではすでに通貨が作成されています。"
  end

  defp render_error(:name, options) do
    "`#{options["name"]}`という名前の通貨は存在しています。別の名前を使用してください。"
  end

  defp render_error(:unit, options) do
    "`#{options["unit"]}`という単位の通貨は存在しています。別の単位を使用してください。"
  end

  defp render_error(:invalid_parameter, _) do
    "通貨の名前は2から16文字以内の英数字、単位は1から10文字以内の英小文字を使ってください。"
  end

  defp render_error(:permission, _) do
    "実行には管理者権限が必要です。"
  end

  defp render_error(:invalid_amount, _) do
    "不正な金額です。1以上4294967295以下である必要があります。"
  end

  defp render_error(:run_in_dm, _) do
    "DMでは実行できません。"
  end

  defp render_error(_, _) do
    "不明なエラーが発生しました。時間を開けてもう一度実行してください。"
  end

  def render(:ok, :ok, options) do
    %{
      type: channel_message_with_source(),
      data: %{
        embeds: [
          %{
            description:
              ~s"\u2705 通貨の作成に成功しました！ `/info unit: #{options["unit"]}`コマンドで通貨の情報をご覧ください。",
            color: color_ok()
          }
        ],
        allowed_mentions: %{
          parse: []
        }
      }
    }
  end

  def render(:error, reason, options) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            title: "エラー",
            description: render_error(reason, options),
            color: color_error()
          }
        ],
        allowed_mentions: %{
          parse: []
        }
      }
    }
  end
end
