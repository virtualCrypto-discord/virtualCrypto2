# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :virtualCrypto,
  ecto_repos: [VirtualCrypto.Repo]

# Configures the endpoint
config :virtualCrypto, VirtualCryptoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "A/SrOULNNrea5K+dL0aCBe2nQzCiXNduURF8NeXOJ9g5TbBZZcUjEHePFDINzTk0",
  render_errors: [view: VirtualCryptoWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: VirtualCrypto.PubSub,
  live_view: [signing_salt: "5bW/V9s1"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :virtualCrypto, VirtualCrypto.Scheduler,
  debug_logging: false,
  overlap: false,
  timezone: :utc,
  jobs: [
    {"@daily", fn -> VirtualCrypto.Money.reset_pool_amount() end},
    {"* * * * *", fn -> VirtualCrypto.Auth.purge_user_access_tokens() end},
    {"* * * * *", fn -> VirtualCrypto.Auth.purge_access_tokens() end},
    {"* * * * *", fn -> VirtualCryptoWeb.IdempotencyLayer.Payments.purge_idempotency_keys() end}
  ]

config :phoenix, :template_engines, leex: Phoenix.LiveView.Engine
