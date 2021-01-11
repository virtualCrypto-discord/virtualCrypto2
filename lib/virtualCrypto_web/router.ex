defmodule VirtualCryptoWeb.Router do
  use VirtualCryptoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end


  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  scope "/", VirtualCryptoWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/login", LoginController, :index
    get "/logout", LogoutController, :index

    get "/callback/discord", DiscordCallbackController, :index

    get "/me", MyPageController, :index
  end

  scope "/api", VirtualCryptoWeb do
    pipe_through :api
    post "/integrations/discord/interactions", InteractionsController, :index

    get "/local/user/me", LocalApiController, :me
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
#      pipe_through [:fetch_session, :protect_from_forgery, :browser]
      live_dashboard "/dashboard", ecto_repos: [VirtualCrypto.Repo], metrics: VirtualCryptoWeb.Telemetry
    end
  end
end
