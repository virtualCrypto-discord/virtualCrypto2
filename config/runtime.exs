import Config

if config_env() == :prod do
  cert_pem = System.get_env("VCRYPTO_WEBHOOK_PROXY_CERT") |> String.replace("#", "\n")
  private_key_pem = System.get_env("VCRYPTO_WEBHOOK_PROXY_KEY") |> String.replace("#", "\n")
  [{ty, der, :not_encrypted}] = :public_key.pem_decode(private_key_pem)

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :virtualCrypto, VirtualCrypto.Repo, socket_options: maybe_ipv6

  if System.get_env("PHX_SERVER") do
    config :virtualCrypto, VirtualCryptoWeb.Endpoint, server: true
  end

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :virtualCrypto, VirtualCrypto.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :virtualCrypto, VirtualCryptoWeb.Endpoint,
    http: [
      port: 8080,
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: secret_key_base

  config :virtualCrypto,
         :bot_token,
         System.get_env("VCRYPTO_BOT_TOKEN") || raise("missing VCRYPTO_BOT_TOKEN")

  config :virtualCrypto,
         :public_key,
         System.get_env("VCRYPTO_PUBLIC_KEY") || raise("missing VCRYPTO_PUBLIC_KEY")

  config :virtualCrypto,
         :client_id,
         System.get_env("VCRYPTO_CLIENT_ID") || raise("missing VCRYPTO_CLIENT_ID")

  config :virtualCrypto,
         :client_secret,
         System.get_env("VCRYPTO_CLIENT_SECRET") || raise("missing VCRYPTO_CLIENT_SECRET")

  config :virtualCrypto,
         :invite_url,
         System.get_env("VCRYPTO_INVITE_URL") || raise("missing VCRYPTO_INVITE_URL")

  config :virtualCrypto,
         :support_guild_invite_url,
         System.get_env("VCRYPTO_SUPPORT_GUILD_INVITE_URL") ||
           raise("missing VCRYPTO_SUPPORT_GUILD_INVITE_URL")

  config :virtualCrypto, VirtualCrypto.Guardian,
    issuer: "virtualCrypto",
    secret_key:
      System.get_env("VCRYPTO_API_JWT_SECRET_KEY") || raise("missing VCRYPTO_API_JWT_SECRET_KEY")

  config :virtualCrypto,
         :site_url,
         System.get_env("VCRYPTO_SITE_URL") || raise("missing VCRYPTO_SITE_URL")

  config :virtualCrypto,
         :discord_oauth2_redirect_uri,
         System.get_env("VCRYPTO_DISCORD_CALLBACK_URI") ||
           raise("missing VCRYPTO_DISCORD_CALLBACK_URI")

  config :virtualCrypto, VirtualCryptoWeb.Endpoint,
    live_view: [
      signing_salt:
        System.get_env("VCRYPTO_LIVE_VIEW_SIGNING_SALT") ||
          raise("missing VCRYPTO_LIVE_VIEW_SIGNING_SALT")
    ]

  config :virtualCrypto, VirtualCrypto.Notification.Webhook.CloudflareWorkers,
    webhook_proxy: "https://vcrypto-webhook-emitter.sumidora.com/",
    ssl: [
      cert:
        :public_key.pem_decode(cert_pem)
        |> Enum.map(fn {:Certificate, der, :not_encrypted} -> der end),
      key: {ty, der}
    ]
end
