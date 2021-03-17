defmodule VirtualCryptoWeb.Api.V1.ClaimView do
  use VirtualCryptoWeb, :view

  def render(conn, d) do
    VirtualCryptoWeb.Api.V1V2.ClaimViewCommon.render(conn, d)
  end
end
