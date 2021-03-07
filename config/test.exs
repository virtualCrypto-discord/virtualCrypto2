use Mix.Config

# Configure your database
config :virtualCrypto, VirtualCrypto.Repo,
  username: "postgres",
  password: "postgres",
  database: "virtualcrypto_test",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool: Ecto.Adapters.SQL.Sandbox,
  log: false

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :virtualCrypto, VirtualCryptoWeb.Endpoint,
  http: [port: 5001],
  https: [
    port: 5000,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ],
  debug_errors: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :virtualCrypto, :bot_token, "NzkxOTg0MzA2NjMyNjU0ODY5.X-XG3Q.AtToj0KWghevc517MP69VqEIn8g"

config :virtualCrypto,
       :public_key,
       "6f8c40ca124f90e6cddb2f1eaba12106a50691215bb50e0e611ae637c9775b42"

config :virtualCrypto, :client_id, "791984306632654869"

config :virtualCrypto, :client_secret, "73yK3Fio6SL4vABMcP6E7xufQApJMpeZ"

config :virtualCrypto,
       :invite_url,
       "https://discord.com/api/oauth2/authorize?client_id=791984306632654869&permissions=379968&scope=applications.commands%20bot"

config :virtualCrypto, :support_guild_invite_url, "https://discord.com/invite/Hgp5DpG"

config :virtualCrypto, VirtualCrypto.Guardian,
  issuer: "virtualCrypto",
  secret_key: "a188rolUOVnGqP7wseWeTW0qkFCfsDMNvbo2Bz6O3dmO9TEyKPD8+Yf1bfiUFRBI"

config :virtualCrypto, :site_url, "https://localhost:4000"

config :virtualCrypto, :discord_oauth2_redirect_uri, "https://localhost:4000/callback/discord"

config :virtualCrypto, VirtualCryptoWeb.Endpoint,
  live_view: [signing_salt: "VxwCTydmJ5qXLUvG8/IH+u14glj9NR3y"]

config :logger, backends: []
