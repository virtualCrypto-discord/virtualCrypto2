defmodule VirtualCryptoWeb.WebAuthView do
  use VirtualCryptoWeb, :view

  def render("token.json", %{access_token: access_token, expires_in: expires_in}) do
    %{
      access_token: access_token,
      expires_in: expires_in,
      token_type: "Bearer"
    }
  end
end
