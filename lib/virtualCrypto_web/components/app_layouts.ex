defmodule VirtualCryptoWeb.AppLayouts do
  use VirtualCryptoWeb, :html

  embed_templates "app_layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  @spec app(map()) :: Phoenix.LiveView.Rendered.t()
  def app(assigns) do
    ~H"""
    <UI.sidebar />
    <UI.Header.wrapper>
      {render_slot(@inner_block)}
    </UI.Header.wrapper>

    <Layouts.flash_group flash={@flash} />
    """
  end
end
