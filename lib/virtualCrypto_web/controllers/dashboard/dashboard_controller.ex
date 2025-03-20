defmodule VirtualCryptoWeb.DashboardController do
  use VirtualCryptoWeb, :controller

  def index(conn, _params) do
    render(conn, :mypage)
  end
end
