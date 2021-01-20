defmodule VirtualCryptoWeb.Api.InteractionsView.Bal do
  def render_line(%{amount: amount, name: name, unit: unit}),
    do: name <> ": " <> Integer.to_string(amount) <> unit

  def render_content([]) do
    "所持通貨一覧\n```\n通貨を持っていません。\n```"
  end

  def render_content(params) do
    "所持通貨一覧\n```yaml\n" <> (params |> Enum.map(&render_line/1) |> Enum.join("\n")) <> "\n```"
  end

  def render(params) do
    %{
      type: 3,
      data: %{
        flags: 64,
        content: render_content(params)
      }
    }
  end
end
