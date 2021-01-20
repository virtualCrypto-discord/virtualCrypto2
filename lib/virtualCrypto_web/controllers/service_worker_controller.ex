defmodule VirtualCryptoWeb.ServiceWorkerController do
  use VirtualCryptoWeb, :controller
  def index(conn, _params) do
    render(conn, "sw.js")
  end
end
