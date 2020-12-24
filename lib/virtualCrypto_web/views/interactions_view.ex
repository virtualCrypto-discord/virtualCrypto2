defmodule VirtualCryptoWeb.InteractionsView do
  use VirtualCryptoWeb, :view

  def render( "interactions.json", %{ params: params } ) do
    %{
      id:   123,
      name: "hoge"
    }
  end
end
