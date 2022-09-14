defmodule VirtualCryptoWeb.Api.InteractionsView.Info do
  import VirtualCryptoWeb.Api.InteractionsView.Util

  def render_title(data) do
    data.name
  end

  def render_all_amount(data) do
    ~s/`#{data.amount}#{data.unit}`/
  end

  def render_user_amount(data, user_amount) do
    ~s/`#{user_amount}#{data.unit}`/
  end

  def render(:error, :must_supply_argument) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            title: "エラー",
            color: color_error(),
            description: "オプションを指定する必要があります。"
          }
        ],
        allowed_mentions: %{
          parse: []
        }
      }
    }
  end

  def render(:error, :not_found) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            title: "エラー",
            color: color_error(),
            description: "通貨が見つかりませんでした。"
          }
        ],
        allowed_mentions: %{
          parse: []
        }
      }
    }
  end

  def render(:ok, %{info: data, amount: user_amount}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            title: render_title(data),
            color: color_brand(),
            fields: [
              %{
                name: "総発行量",
                value: render_all_amount(data),
                inline: true
              },
              %{
                name: "あなたの所持量",
                value: render_user_amount(data, user_amount),
                inline: true
              }
            ]
          }
        ]
      }
    }
  end
end
