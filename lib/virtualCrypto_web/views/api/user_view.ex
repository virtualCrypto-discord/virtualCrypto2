defmodule VirtualCryptoWeb.V1.UserView do
  use VirtualCryptoWeb, :view

  def render("me.json", %{params: params}) do
    %{
      id: params.id,
      name: params.name,
      avatar: params.avatar,
      discriminator: params.discriminator
    }
  end
end
