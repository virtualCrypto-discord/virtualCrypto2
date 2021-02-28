defmodule VirtualCryptoWeb.OAuth2.TokenRevocationController do
  use VirtualCryptoWeb, :controller

  def post(conn, %{"token" => token}) do
    VirtualCrypto.Guardian.revoke(token)
    conn |> render("response.json")
  end

  def post(conn, %{"jti" => jti, "typ" => "access", "kind" => kind})
      when kind in ["app", "user"] do
    VirtualCrypto.Guardian.revoke_with_jti(%{"jti" => jti, "kind" => kind})
    conn |> render("response.json")
  end

  def post(conn, _) do
    conn |> put_status(400) |> render("error.json")
  end
end
