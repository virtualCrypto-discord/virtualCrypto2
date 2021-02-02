defmodule VirtualCryptoWeb.DocumentController do
  use VirtualCryptoWeb, :controller
  @base "https://github.com/virtualCrypto-discord/virtualcrypto-docs/tree/master/docs/"

  def index(conn, _) do
    render(conn, "index.html")
  end

  def commands(conn, _) do
    conn
    |> redirect(external: @base <> "Commands.md")
  end

  def about(conn, _) do
    conn
    |> redirect(external: @base <> "About.md")
  end

  def api(conn, _) do
    conn
    |> redirect(external: @base <> "Api.md")
  end
end
