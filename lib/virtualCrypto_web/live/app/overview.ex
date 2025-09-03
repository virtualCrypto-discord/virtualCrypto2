defmodule VirtualCryptoWeb.App.OverviewLive do
  use VirtualCryptoWeb, :app_live_view

  def render(assigns) do
    ~H"""
      <AppLayouts.app flash={@flash}>
        <h1>Content</h1>
      </AppLayouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
