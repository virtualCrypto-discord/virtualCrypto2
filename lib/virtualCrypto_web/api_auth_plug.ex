defmodule VirtualCryptoWeb.AuthErrorHandler do
  @behaviour Guardian.Plug.ErrorHandler
  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> Plug.Conn.send_resp(401,"Unauthorized")
  end
end
defmodule VirtualCryptoWeb.ApiAuthPlug do
  use Guardian.Plug.Pipeline, otp_app: :virtualCrypto,
  module: VirtualCrypto.Guardian,
  error_handler: VirtualCryptoWeb.AuthErrorHandler
  @claims %{iss: "virtualCrypto"}

  plug Guardian.Plug.VerifySession, claims: @claims
  plug Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
end
