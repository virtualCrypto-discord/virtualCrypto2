defmodule VirtualCryptoWeb.InteractionsController do
  use VirtualCryptoWeb, :controller

  def create( conn, params ) do
    render( conn, "interactions.json", params: params )
  end
end
