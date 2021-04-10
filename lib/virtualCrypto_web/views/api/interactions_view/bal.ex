defmodule VirtualCryptoWeb.Api.InteractionsView.Bal do
  import VirtualCryptoWeb.Api.InteractionsView.Util

  def render_line(%{
        asset: %VirtualCrypto.Money.Asset{amount: amount},
        currency: %VirtualCrypto.Money.Info{unit: unit, name: name}
      }),
      do: ~s/#{name}: #{amount} #{unit}/

  def render_content([]) do
    "所持通貨一覧\n```\n通貨を持っていません。\n```"
  end

  def render_content(params) do
    "所持通貨一覧\n```yaml\n" <> (params |> Enum.map(&render_line/1) |> Enum.join("\n")) <> "\n```"
  end

  def render(params) do
    %{
      type: channel_message_with_source(),
      data: %{
        flags: 64,
        content: render_content(params)
      }
    }
  end
end
