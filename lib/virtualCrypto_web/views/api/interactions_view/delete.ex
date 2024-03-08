defmodule VirtualCryptoWeb.Api.InteractionsView.Delete do
  import VirtualCryptoWeb.Api.InteractionsView.Util
  alias VirtualCryptoWeb.Interaction.CustomId

  defp render_error(:not_exist) do
    "エラー: このサーバーに通貨が存在しません。"
  end

  defp render_error(:out_of_term) do
    "エラー: 作成から72時間以上経過しているため削除できません。"
  end

  defp render_error(:confirmation_failed) do
    "エラー: 確認に失敗しました。再度`\\delete`コマンドを実行してください。"
  end

  def render(_, :confirm, currency) do
    required_text = "delete #{currency.unit}"

    %{
      type: modal(),
      data: %{
        title: "通貨の削除",
        custom_id: CustomId.encode(0, CustomId.UI.Modal.confirm_currency_delete()),
        components: [
          %{
            type: action_row(),
            components: [
              %{
                type: text_input(),
                custom_id: "confirm",
                style: text_input_style_short(),
                label: "確認のため、「#{required_text}」と入力してください。",
                min_length: String.length(required_text),
                max_length: String.length(required_text),
                placeholder: required_text
              }
            ]
          }
        ]
      }
    }
  end

  def render(_, :deleted, _currency) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: "通貨を削除しました。",
        allowed_mentions: %{
          parse: []
        }
      }
    }
  end

  def render(:error, err, _) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: render_error(err),
        allowed_mentions: %{
          parse: []
        }
      }
    }
  end
end
