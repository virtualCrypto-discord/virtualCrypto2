# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :virtualCrypto,
  ecto_repos: [VirtualCrypto.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :virtualCrypto, VirtualCryptoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: VirtualCryptoWeb.ErrorHTML, json: VirtualCryptoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: VirtualCrypto.PubSub,
  live_view: [signing_salt: "aiQYikhx"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.1",
  virtualCrypto: [
    args:
      ~w(js/app.js
       js/credential-manager-cb.js
       js/credential-manager-common.js
       js/credential-manager-dom.js
       js/credential-manager-sw.js
        js/sw.js --bundle
        --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  virtualCrypto: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :virtualCrypto, VirtualCrypto.Scheduler,
  debug_logging: false,
  overlap: false,
  timezone: :utc,
  jobs: [
    {"@daily", &VirtualCrypto.Money.reset_pool_amount/0},
    {"* * * * *", &VirtualCrypto.Auth.purge_user_access_tokens/0},
    {"* * * * *", &VirtualCrypto.Auth.purge_access_tokens/0},
    {"* * * * *", &VirtualCryptoWeb.IdempotencyLayer.Payments.purge_idempotency_keys/0}
  ]

config :virtualCrypto, :discord_ua_website, "https://vcrypto.sumidora.com"
config :virtualCrypto, :discord_ua_version, "1"

config :phoenix, :template_engines, leex: Phoenix.LiveView.Engine

config :hammer,
  backend:
    {Hammer.Backend.ETS,
     [expiry_ms: 4 * 24 * 60 * 60 * 1000, cleanup_interval_ms: 10 * 60 * 1000]}
