defmodule VirtualCrypto.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Cachex.Spec

  @impl true
  def start(_type, _args) do
    children = [
      VirtualCryptoWeb.Telemetry,
      VirtualCrypto.Repo,
      {DNSCluster, query: Application.get_env(:virtualCrypto, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: VirtualCrypto.PubSub},
      # Start a worker by calling: VirtualCrypto.Worker.start_link(arg)
      # {VirtualCrypto.Worker, arg},
      # Start to serve requests, typically the last entry
      VirtualCryptoWeb.Endpoint,
      VirtualCrypto.Scheduler,
      {Discord.Api.UserCache, expiration: expiration(default: 15 * 60 * 1000), stats: true},
      {Discord.Api.GuildCache, expiration: expiration(default: 15 * 60 * 1000), stats: true}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VirtualCrypto.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VirtualCryptoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
