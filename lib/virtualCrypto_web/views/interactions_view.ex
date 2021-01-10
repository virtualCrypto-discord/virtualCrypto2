defmodule VirtualCryptoWeb.InteractionsView do
  use VirtualCryptoWeb, :view

  def render("pong.json", _) do
    %{
      type: 1
    }
  end

  def render("bal.json", %{params: params}) do
    VirtualCryptoWeb.InteractionsView.Bal.render(params)
  end

  def render("pay.json", %{
        params: {res, v}
      }) do
    VirtualCryptoWeb.InteractionsView.Pay.render(res,v)
  end

  def render("give.json", %{params: {res,v}}) do
    VirtualCryptoWeb.InteractionsView.Give.render(res,v)
  end

  def render("create.json", %{params: {response, reason, options}}) do
    VirtualCryptoWeb.InteractionsView.Create.render(response, reason, options)
  end

  def render("info.json", %{params: {response, data, user_amount, guild, options}}) do
    VirtualCryptoWeb.InteractionsView.Info.render(response, data, user_amount, guild, options)
  end

  def render("help.json", %{params: params}) do
    %{
      type: 4,
      data: %{
        tts: false,
        content: "Congrats on sending your command!",
        embeds: [],
        allowed_mentions: []
      }
    }
  end

  def render("invite.json", %{params: {bot_invite_url, guild_invite_url}}) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content: ~s/VirtualCryptoの招待: #{bot_invite_url}\nVirtualCryptoのサポートサーバー: #{guild_invite_url}/
      }
    }
  end
end
