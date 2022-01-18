defmodule VirtualCrypto.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Cachex.Spec

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      VirtualCrypto.Repo,
      # Start the Telemetry supervisor
      VirtualCryptoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: VirtualCrypto.PubSub},
      # Start the Endpoint (http/https)
      VirtualCryptoWeb.Endpoint,
      # Start a worker by calling: VirtualCrypto.Worker.start_link(arg)
      # {VirtualCrypto.Worker, arg}

      VirtualCrypto.Scheduler,
      {Discord.Api.UserCache, expiration: expiration(default: 15 * 60 * 1000), stats: true}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VirtualCrypto.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    VirtualCryptoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
