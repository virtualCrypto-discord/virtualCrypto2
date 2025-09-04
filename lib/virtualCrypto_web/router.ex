defmodule VirtualCryptoWeb.Router do
  use VirtualCryptoWeb, :router
  alias VirtualCryptoWeb.AppLive

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VirtualCryptoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_auth do
    plug VirtualCryptoWeb.AuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug VirtualCryptoWeb.ApiAuthPlug
  end

  scope "/", VirtualCryptoWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/" do
    pipe_through :browser
    pipe_through :browser_auth

    scope "/app" do
      live "/", AppLive.Overview
      live "/balances", AppLive.Balances
    end

    get "/applications/:id", ApplicationController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", VirtualCryptoWeb do
  #   pipe_through :api
  # end

  scope "/", VirtualCryptoWeb do
    pipe_through :browser

    get "/logout", LogoutController, :index

    get "/invite", OutgoingController, :bot
    get "/support", OutgoingController, :guild

    get "/callback/discord", WebAuthController, :discord_callback

    get "/applications/verification", ApplicationController, :readme

    scope "/document" do
      get "/", DocumentController, :index
      get "/about", DocumentController, :about
      get "/commands", DocumentController, :commands
      get "/api", DocumentController, :api
    end

    # required auth
    scope "/" do
      pipe_through :browser_auth
      live "/me", DashboardApplication
      get "/applications/:id", ApplicationController, :index
    end
  end

  scope "/", VirtualCryptoWeb do
    pipe_through :browser

    live "/contract/:id", Contract.ApproveApplication
  end

  scope "/", VirtualCryptoWeb do
    pipe_through :browser
    pipe_through :browser_auth

    live "/applications/:id/connect", ConnectApplication
  end

  scope "/oauth2", VirtualCryptoWeb.OAuth2 do
    scope "/authorize" do
      pipe_through :browser
      pipe_through :browser_auth
      get "/", AuthorizeController, :get
      post "/", AuthorizeController, :post
    end

    scope "/" do
      pipe_through :api
      post "/token", TokenController, :post
      post "/token/revoke", TokenRevocationController, :post

      scope "/clients" do
        pipe_through :api_auth
        get "/", ClientsController, :get
        post "/", ClientsController, :post

        scope "/@me" do
          get "/", ClientController, :get
          patch "/", ClientController, :patch
        end
      end
    end
  end

  scope "/", VirtualCryptoWeb do
    post "/token", WebAuthController, :token
  end

  scope "/api", VirtualCryptoWeb.Api do
    pipe_through :api
    post "/integrations/discord/interactions", InteractionsController, :index
    # deprecated
    scope "/v1", V1, as: :v1 do
      get "/moneys", InfoController, :index

      get "/currencies/:id", InfoController, :index
      get "/currencies", InfoController, :index

      scope "/" do
        pipe_through :api_auth
        get "/users/@me/claims", ClaimController, :me
        get "/users/@me/claims/:id", ClaimController, :get_by_id
        post "/users/@me/claims", ClaimController, :post
        patch "/users/@me/claims/:id", ClaimController, :patch
        post "/users/@me/transactions", UserTransactionController, :post
      end
    end

    # deprecated
    scope "/v1", V1V2, as: :v1 do
      scope "/" do
        pipe_through :api_auth

        get "/users/@me", UserController, :me
        get "/users/@me/balances", BalanceController, :balance
      end
    end

    scope "/v2", V2, as: :v2 do
      get "/currencies/:id", CurrenciesController, :index
      get "/currencies", CurrenciesController, :index

      scope "/" do
        pipe_through :api_auth
        get "/users/@me/claims", ClaimController, :me
        get "/users/@me/claims/:id", ClaimController, :get_by_id
        post "/users/@me/claims", ClaimController, :post
        patch "/users/@me/claims/:id", ClaimController, :patch
        post "/users/@me/transactions", UserTransactionController, :post
      end
    end

    scope "/v2", V1V2, as: :v2 do
      scope "/" do
        pipe_through :api_auth

        get "/users/@me", UserController, :me
        get "/users/@me/balances", BalanceController, :balance
      end
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:virtualCrypto, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard",
        ecto_repos: [VirtualCrypto.Repo],
        metrics: VirtualCryptoWeb.Telemetry
    end
  end
end
