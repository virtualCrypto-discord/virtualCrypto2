defmodule VirtualCryptoWeb.Router do
  use VirtualCryptoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  pipeline :browser_auth do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug VirtualCryptoWeb.AuthPlug
  end
  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :oauth2 do
    plug :fetch_session
    plug VirtualCryptoWeb.ApiAuthPlug
  end

  scope "/", VirtualCryptoWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/login", LoginController, :index
    get "/logout", LogoutController, :index

    get "/invite", OutgoingController, :bot
    get "/support", OutgoingController, :guild

    get "/callback/discord", DiscordCallbackController, :index

    get "/me", MyPageController, :index
  end

  scope "/api", VirtualCryptoWeb do
    pipe_through :api
    post "/integrations/discord/interactions", InteractionsController, :index

    scope "/v1", V1 do
      pipe_through :oauth2

      get "/user/@me", UserController, :me
      get "/balance/@me", BalanceController, :balance
    end
  end

  scope "/oauth2",VirtualCryptoWeb do
    scope "/authorize" do
      pipe_through :browser_auth

      get "/",Oauth2Controller,:authorize
      post "/",Oauth2Controller,:authorize_action
    end
    scope "/token" do
      pipe_through :api
      post "/",Oauth2Controller,:token
    end
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
