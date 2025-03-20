defmodule VirtualCryptoWeb.OAuth2.TokenRevocationJSON do
  def response() do
    %{}
  end

  def error() do
    %{
      error: :invalid_request,
      error_description: :token_or_token_id_type_and_kind_is_not_found_or_invalid_kind_or_type
    }
  end
end
