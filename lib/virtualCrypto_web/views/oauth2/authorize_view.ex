defmodule VirtualCryptoWeb.OAuth2.AuthorizeView do
  use VirtualCryptoWeb, :view
  # authorize.html.eex
  import Phoenix.Controller, only: [get_csrf_token: 0]
end
