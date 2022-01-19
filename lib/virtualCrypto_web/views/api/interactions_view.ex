defmodule VirtualCryptoWeb.Api.InteractionsView do
  use VirtualCryptoWeb, :view
  alias VirtualCryptoWeb.Api.InteractionsView, as: InteractionsView
  import VirtualCryptoWeb.Api.InteractionsView.Util

  def render("pong.json", _) do
    %{
      type: pong()
    }
  end

  def render("bal.json", %{params: params}) do
    InteractionsView.Bal.render(params)
  end

  def render("pay.json", %{
        params: {res, v}
      }) do
    InteractionsView.Pay.render(res, v)
  end

  def render("give.json", %{params: {res, v}}) do
    InteractionsView.Give.render(res, v)
  end

  def render("create.json", %{params: {response, reason, options}}) do
    InteractionsView.Create.render(response, reason, options)
  end

  def render("info.json", %{params: {status, data}}) do
    InteractionsView.Info.render(status, data)
  end

  def render("help.json", %{params: {logo_url, bot_invite_url, guild_invite_url, site_url}}) do
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

  def render("invite.json", %{params: {logo_url, bot_invite_url, guild_invite_url}}) do
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

  def render("claim.json", %{params: params}) do
    InteractionsView.Claim.render(params)
  end

  def render("autocomplete.json", %{params: params}) do
    %{
      type: 8,
      data: %{
        choices: params
      }
    }
  end
end
