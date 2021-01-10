defmodule VirtualCryptoWeb.InteractionsView.Info do
  import VirtualCryptoWeb.InteractionsView.Util

  def render_error(%{}) do
    "エラー: このサーバーでは通貨は作成されていません。"
  end

  def render_error(_) do
    "エラー: そのような名前や単位の通貨は存在しません。"
  end

  def render_title(data) do
    ~s/#{data.name} の情報\n\n/
  end

  def render_all_amount(data) do
    ~s/総発行量: #{to_string(data.amount)}#{data.unit}\n/
  end

  def render_guild(guild) do
    case guild do
      nil -> "不明\n"
      guild -> ~s/発行元サーバー: #{guild["name"]}\n/
    end
  end

  def render_user_amount(data, user_amount) do
    ~s/あなたが持っている量: #{user_amount}#{data.unit}\n/
  end

  def render(:error, _, _, _, options) do
    %{
      type: 3,
      data: %{
        tts: false,
        flags: 64,
        content: render_error(options),
        embeds: [],
        allowed_mentions: []
      }
    }
  end

  def render(:ok, data, user_amount, guild, _) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content: ~s/```\n#{render_title data}#{render_all_amount data}#{render_guild guild}#{render_user_amount data, user_amount}```/
      }
    }
  end

end
