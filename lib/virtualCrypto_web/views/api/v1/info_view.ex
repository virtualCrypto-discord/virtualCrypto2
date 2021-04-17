defmodule VirtualCryptoWeb.Api.V1.InfoView do
  use VirtualCryptoWeb, :view

  def render(conn, d) do
    VirtualCryptoWeb.Api.V1V2.CurrenciesViewCommon.render(conn, d)
  end
end
