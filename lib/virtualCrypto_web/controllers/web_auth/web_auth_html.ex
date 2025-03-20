defmodule VirtualCryptoWeb.WebAuthHTML do
  use VirtualCryptoWeb, :html
  use PhoenixHTMLHelpers

  attr :access_token, :string, required: true
  attr :redirect_to, :string, required: true
  attr :expires_in, :integer, required: true

  def redirect(assigns) do
    ~H"""
    <%= content_tag(
      :script,
      raw(""),
      type: "text/javascript",
      src: "/assets/credential-manager-cb.js",
      data: [redirect_to: @redirect_to,access_token: @access_token,expires_in: @expires_in])
    %>
    """
  end
end
