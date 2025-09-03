defmodule VirtualCryptoWeb.PageController do
  use VirtualCryptoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
