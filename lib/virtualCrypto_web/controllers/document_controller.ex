defmodule VirtualCryptoWeb.DocumentController do
  use VirtualCryptoWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def commands(conn, _) do
    render(conn, "commands.html")
  end
end