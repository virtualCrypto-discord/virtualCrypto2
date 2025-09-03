defmodule VirtualCryptoWeb.App.OverviewLive do
  use VirtualCryptoWeb, :live_view

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

  @impl true
  def handle_params(_params, uri, socket) do
    path = URI.parse(uri).path
    {:noreply, assign(socket, current_path: path)}
  end
end
