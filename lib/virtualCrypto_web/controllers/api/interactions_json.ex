defmodule VirtualCryptoWeb.Api.InteractionsJSON do
  alias VirtualCryptoWeb.Api.Interactions, as: Interactions
  import VirtualCryptoWeb.Api.Interactions.Util

  def pong_resp(%{}), do: %{type: pong()}
  def bal(%{params: params}), do: Interactions.Bal.render(params)
  def pay(%{params: {res, v}}), do: Interactions.Pay.render(res, v)
  def give(%{params: {res, v}}), do: Interactions.Give.render(res, v)

  def create(%{params: {response, reason, options}}),
    do: Interactions.Create.render(response, reason, options)

  def delete(%{params: {status, reason, data}}),
    do: Interactions.Delete.render(status, reason, data)

  def info(%{params: {status, data}}), do: Interactions.Info.render(status, data)
  def claim(%{params: params}), do: Interactions.Claim.render(params)

  def help(%{params: {logo_url, bot_invite_url, guild_invite_url, site_url}}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: ephemeral(),
        embeds: [
          %{
            color: color_brand(),
            title: "VirtualCrypto",
            thumbnail: %{
              url: logo_url
            },
            description: ~s/VirtualCryptoはDiscord上でサーバーに独自の通貨を作成できるBotです。
[コマンドの使い方の詳細](#{site_url}\/document\/commands)
[公式サイト](#{site_url})
[Botの招待](#{bot_invite_url})
[サポートサーバーの招待](#{guild_invite_url})/
          }
        ]
      }
    }
  end

  def invite(%{params: {logo_url, bot_invite_url, guild_invite_url}}) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: ephemeral(),
        embeds: [
          %{
            color: color_brand(),
            title: "VirtualCrypto",
            thumbnail: %{
              url: logo_url
            },
            description: "[Botの招待](#{bot_invite_url})\n[サポートサーバーの招待](#{guild_invite_url})"
          }
        ]
      }
    }
  end

  def autocomplete(%{params: params}) do
    %{
      type: 8,
      data: %{
        choices: params
      }
    }
  end
end
