defmodule VirtualCryptoWeb.AuthErrorHandler do
  @behaviour Guardian.Plug.ErrorHandler
  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    case type do
      :unauthenticated ->
        conn
        |> Plug.Conn.send_resp(400, """
        {
          "error": "invalid_request"
        }
        """)

      x when x in [:unauthorized,:invalid_token] ->
        conn
        |> Plug.Conn.put_resp_header(
          "WWW-Authenticate",
          [
            "Bearer"
          ]
          |> Enum.join(",")
        )
        |> Plug.Conn.send_resp(401, """
        {
          "error": "invalid_token"
        }
        """)
    end
  end
end

defmodule VirtualCryptoWeb.ApiAuthPlug do
  use Guardian.Plug.Pipeline,
    otp_app: :virtualCrypto,
    module: VirtualCrypto.Guardian,
    error_handler: VirtualCryptoWeb.AuthErrorHandler

  @claims %{iss: "virtualCrypto"}

  plug Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
end
