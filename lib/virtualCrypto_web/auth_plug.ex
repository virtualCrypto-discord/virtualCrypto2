defmodule VirtualCryptoWeb.AuthPlug do
  import Plug.Conn, only: [get_session: 2, halt: 1]
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user) do
      nil ->
        conn
        |> redirect(external: Application.get_env(:virtualCrypto, :login_url))
        |> halt()
      user ->
        VirtualCrypto.Auth.refresh_user(user.id)
        conn
    end
  end
end
