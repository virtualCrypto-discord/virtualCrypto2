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
      nil ->
        nil

      guild ->
        %{
          name: ~s/#{guild["name"]}/
        }
        |> Map.merge(
          case Map.fetch(guild, "icon") do
            {:ok, nil} ->
              %{}

            {:ok, hash} ->
              format =
                if String.starts_with?(hash, "a_") do
                  "gif"
                else
                  "webp"
                end

              %{
                icon_url: ~s"https://cdn.discordapp.com/icons/#{guild["id"]}/#{hash}.#{format}"
              }

            :error ->
              %{}
          end
        )
    end
  end

  def render_user_amount(data, user_amount) do
    ~s/`#{user_amount}#{data.unit}`/
  end
  def render_deletable(data) do
    if data.deletable do
      "はい"
    else
      "いいえ"
    end
  end

  def render(:error, :must_supply_argument_when_run_in_dm) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            title: "エラー",
            color: color_error(),
            description: "DMで実行する場合はオプションを指定する必要があります。"
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

  def render(:ok, %{info: data, amount: user_amount, guild: guild}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        embeds: [
          %{
            title: render_title(data),
            author: render_guild(guild),
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
              },%{
                name: "削除可能",
                value: render_deletable(data),
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
