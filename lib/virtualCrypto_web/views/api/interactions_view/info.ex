defmodule VirtualCryptoWeb.Api.InteractionsView.Info do
  import VirtualCryptoWeb.Api.InteractionsView.Util

  def render_title(data) do
    data.name
  end

  def render_all_amount(data) do
    ~s/`#{data.amount}#{data.unit}`/
  end

  def render_pool_amount(data) do
    ~s/`#{data.pool_amount}#{data.unit}`/
  end

  def render_guild(guild) do
    case guild do
      nil -> "`情報の取得に失敗しました。`"
      guild -> ~s/#{guild["name"]}/
    end
  end

  def render_user_amount(data, user_amount) do
    ~s/`#{user_amount}#{data.unit}`/
  end

  def render(:error, _, _, _) do
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

  def render(:ok, data, user_amount, guild) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            title: render_title(data),
            author:
              %{
                name: render_guild(guild)
              }
              |> Map.merge(
                case Map.fetch(guild, "icon") do
                  {:ok, hash} ->
                    format =
                      if String.starts_with?(hash, "a_") do
                        "gif"
                      else
                        "webp"
                      end

                    %{
                      icon_url:
                        IO.inspect(
                          ~s"https://cdn.discordapp.com/icons/#{guild["id"]}/#{hash}.#{format}"
                        )
                    }

                  :error ->
                    %{}
                end
              ),
            color: color_brand(),
            fields: [
              %{
                name: "総発行量",
                value: render_all_amount(data),
                inline: true
              },
              %{
                name: "発行枠",
                value: render_pool_amount(data),
                inline: true
              },
              %{
                name: "あなたの所持量",
                value: render_user_amount(data, user_amount),
                inline: true
              }
            ],
            footer: %{
              text: "発行枠は一日一回総発行量の0.5%増加し、最大で総発行量の3.5%となります。"
            }
          }
        ]
      }
    }
  end
end
