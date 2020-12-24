defmodule VirtualCryptoWeb.InteractionsView do
  use VirtualCryptoWeb, :view

  def render( "interactions.json", %{ params: %{"type" => 1} } ) do
    %{
      type: 1
    }
  end

  def render( "interactions.json", %{ params: params } = request ) do
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
