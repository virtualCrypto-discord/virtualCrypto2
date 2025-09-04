defmodule VirtualCrypto.MixProject do
  use Mix.Project

  def project do
    [
      app: :virtualCrypto,
      version: "3.0.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {VirtualCrypto.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:simpleicons,
       github: "simple-icons/simple-icons",
       tag: "14.12.0",
       sparse: "icons",
       app: false,
       compile: false,
       depth: 1},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:elixir_uuid, "~> 1.2"},
      {:tzdata, "~> 1.1"},
      {:excoveralls, "~> 0.3", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:hammer, "~> 6.0"},
      {:castore, "~> 0.1.11"},
      {:oauth2, "~> 2.0"},
      {:guardian, "~> 2.0"},
      {:quantum, "~> 3.0"},
      {:ex_url, "~> 1.3"},
      {:cachex, "~> 3.3"},
      {:ecto_psql_extras, "~> 0.8.8"},
      {:plug_cowboy, "~> 2.0"},
      {:httpoison, "~> 1.7"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:electric, ">= 1.0.0-beta.18"},
      {:phoenix_sync, "~> 0.5.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind virtualCrypto", "esbuild virtualCrypto"],
      "assets.deploy": [
        "tailwind virtualCrypto --minify",
        "esbuild virtualCrypto --minify",
        "phx.digest"
      ],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"],
      "register.commands": ["run priv/register-commands.exs"]
    ]
  end
end
