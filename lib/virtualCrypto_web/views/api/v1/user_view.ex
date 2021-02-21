defmodule VirtualCryptoWeb.Api.V1.UserView do
  use VirtualCryptoWeb, :view

  def render("me.json", %{params: params}) do
    params
  end
end
