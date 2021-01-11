defmodule VirtualCryptoWeb.ApiAuthPlug do
  import Plug.Conn, only: [get_session: 2, halt: 1, put_resp_content_type: 2, send_resp: 3]
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user) do
      nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(401, 'Unauthorized')
        |> halt()
      user ->
        conn
    end
  end
end
