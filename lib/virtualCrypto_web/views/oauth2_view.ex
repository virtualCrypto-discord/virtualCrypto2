defmodule VirtualCryptoWeb.Oauth2View do
  use VirtualCryptoWeb, :view
  import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]
end
