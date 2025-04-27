defmodule VirtualCryptoWeb.ServiceWorkerPlug do
  def init(options), do: options

  def call(conn, opts) do
    if conn.path_info == ["assets", "sw.js"] do
      conn
      |> Plug.Conn.put_resp_header("Service-Worker-Allowed", "/")
    else
      conn
    end
  end
end
