defmodule VirtualCryptoWeb.UI do
  use VirtualCryptoWeb, :ui
  alias VirtualCryptoWeb.UI, as: UI

  def sidebar(assigns) do
    import UI.Sidebar

    ~H"""
    <.mobile />
    <.desktop />
    """
  end
end
