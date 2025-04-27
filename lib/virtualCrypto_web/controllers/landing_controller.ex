defmodule VirtualCryptoWeb.LandingController do
  use VirtualCryptoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def features(conn, _params) do
    render(conn, :features)
  end
end
