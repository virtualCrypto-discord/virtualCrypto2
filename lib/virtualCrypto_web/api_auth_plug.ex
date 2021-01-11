defmodule VirtualCryptoWeb.ApiAuthPlug do
  import Plug.Conn, only: [get_session: 2, halt: 1, put_resp_content_type: 2, send_resp: 3]
  import Phoenix.Controller, only: [redirect: 2]

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(401, 'Unauthorized')
    |> halt()
  end

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :jwt) do
      nil ->
        # TODO: Headerのベアラートークンも確認する！
        conn |> unauthorized
      jwt ->
        {:ok, data} = VirtualCrypto.Guardian.decode_and_verify(jwt)
        if !(VirtualCrypto.Auth.get_user_from_id(data["sub"])) do
          conn |> unauthorized
        else
          conn
        end
    end
  end
end
