defmodule VirtualCryptoWeb.DocumentController do
  use VirtualCryptoWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def commands(conn, _) do
    {:ok, md} = File.read "./docs/parsed/commands.md.html"
    render conn, "commands.html", md: md
  end
end
