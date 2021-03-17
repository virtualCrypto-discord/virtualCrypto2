defmodule VirtualCryptoWeb.Api.V2.CurrenciesView do
  use VirtualCryptoWeb, :view

  def render(conn, d) do
    VirtualCryptoWeb.Api.V1V2.CurrenciesViewCommon.render(conn, d)
  end
end
