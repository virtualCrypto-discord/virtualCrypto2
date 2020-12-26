defmodule VirtualCryptoWeb.InteractionsView do
  use VirtualCryptoWeb, :view

  def render("pong.json", _) do
    %{
      type: 1
    }
  end

  def render("bal.json", %{params: params}) do
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

  def render("info.json", %{params: params}) do
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

  def render("invite.json", %{params: params}) do
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
end
