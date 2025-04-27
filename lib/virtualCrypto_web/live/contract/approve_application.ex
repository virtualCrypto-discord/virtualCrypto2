defmodule VirtualCryptoWeb.Contract.ApproveApplication do
  use Phoenix.LiveView, layout: {VirtualCryptoWeb.Layouts, :authorization}
  alias VirtualCrypto.Auth

  def mount(params, session, socket) do
    {:ok, socket}
  end
end
