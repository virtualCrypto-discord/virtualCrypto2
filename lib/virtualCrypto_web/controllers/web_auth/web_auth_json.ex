defmodule VirtualCryptoWeb.WebAuthJSON do
  def token(%{access_token: access_token, expires_in: expires_in}) do
    %{
      access_token: access_token,
      expires_in: expires_in,
      token_type: "Bearer"
    }
  end

end
