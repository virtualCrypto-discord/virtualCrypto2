defmodule VirtualCryptoWeb.InteractionsView do
  use VirtualCryptoWeb, :view

  def render( "pong.json", _ ) do
    %{
      type: 1
    }
  end

  def render( "bal.json", %{ params: params } ) do
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

  def render( "pay.json", %{ params: params } ) do
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

  def render( "give.json", %{ params: params } ) do
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

  def render( "create.json", %{ params: {:ok, message} } ) do
    %{
      type: 4,
      data: %{
        tts: false,
        embeds: [
          %{
            description: "\u2705 " <> message,
            color: 0x38ea42
          }
        ],
        allowed_mentions: []
      }
    }
  end

  def render( "create.json", %{ params: {:error, message} } ) do
    %{
      type: 3,
      data: %{
        tts: false,
        flags: 64,
        content: "エラー: " <> message,
        embeds: [],
        allowed_mentions: []
      }
    }
  end

  def render( "info.json", %{ params: params } ) do
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

  def render( "help.json", %{ params: params } ) do
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

  def render( "invite.json", %{ params: params } ) do
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
