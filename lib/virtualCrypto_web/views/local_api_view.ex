defmodule VirtualCryptoWeb.LocalApiView do
  use VirtualCryptoWeb, :view

  def render("me.json", %{params: params}) do
    %{
      id: params.id,
      name: params.name,
      avatar: params.avatar
    }
  end
end