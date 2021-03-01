defmodule VirtualCryptoWeb.OAuth2.TokenRevocationView do
  def render("response.json", _) do
    %{}
  end

  def render("error.json", _) do
    %{
      error: :invalid_request,
      error_description: :token_or_token_id_type_and_kind_is_not_found_or_invalid_kind_or_type
    }
  end
end
