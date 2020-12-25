defmodule VirtualCryptoWeb.InteractionsView do
  use VirtualCryptoWeb, :view

  defp mention(id) do
    "<@" <> id <> ">"
  end
  defp render_give_error(:not_found_money)do
    "エラー: 通貨が存在しません。"
  end
  defp render_give_error(:not_found_sender_asset)do
     "エラー: 通貨を持っていません。"
  end
  defp render_give_error(:not_enough_amount) do
    "エラー: 通貨が不足しています。"
  end

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
        params: {:ok, %{unit: unit, receiver: receiver, sender: sender, amount: amount}}
      }) do
    %{
      type: 3,
      data: %{
        embeds: [
          %{
            "description" =>
              mention(sender) <> "から" <> mention(receiver) <> "へ" <>  Integer.to_string(amount) <> unit <> "送金されました。",
              color: 0x38ea42
          }
        ],
        allowed_mentions: []
      }
    }
  end

  def render("give.json", %{params: {:ok, {receiver, amount, unit}}}) do
    %{
      type: 3,
      data: %{
        tts: false,
        embeds: [
          %{
            "description" => "\u2705 " <>mention(receiver) <> "へ" <> Integer.to_string(amount) <> unit <> "発行されました。",
            color: 0x38ea42
          }
        ],
        allowed_mentions: []
      }
    }
  end
  def render("give.json", %{params: {:error, v}}) do
    %{
      type: 3,
      data: %{
        tts: false,
        flags: 64,
        content: render_give_error(v),
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
