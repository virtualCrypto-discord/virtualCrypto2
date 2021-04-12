defmodule VirtualCryptoWeb.Api.InteractionsView.Info do
  import VirtualCryptoWeb.Api.InteractionsView.Util

  def render_error() do
    "エラー: 通貨が見つかりませんでした。"
  end

  def render_title(data) do
    ~s/#{data.name} の情報\n\n/
  end

  def render_all_amount(data) do
    ~s/総発行量: #{data.amount} #{data.unit}\n/
  end

  def render_pool_amount(data) do
    ~s/発行枠: #{data.pool_amount} #{data.unit}(一日一回総発行量の0.5%増加。最大で総発行量の3.5%)\n/
  end

  def render_guild(guild) do
    case guild do
      nil -> "発行元サーバーの情報の取得に失敗しました。\n"
      guild -> ~s/発行元サーバー: #{guild["name"]}\n/
    end
  end

  def render_user_amount(data, user_amount) do
    ~s/あなたが持っている量: #{user_amount} #{data.unit}\n/
  end

  def render(:error, _, _, _) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: render_error(),
        allowed_mentions: %{
          parse: []
        }
      }
    }
  end

  def render(:ok, data, user_amount, guild) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content:
          ~s/```\n#{render_title(data)}#{render_all_amount(data)}#{render_pool_amount(data)}#{
            render_guild(guild)
          }#{render_user_amount(data, user_amount)}```/
      }
    }
  end
end
