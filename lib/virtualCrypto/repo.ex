defmodule VirtualCrypto.Repo do
  use Ecto.Repo,
    otp_app: :virtualCrypto,
    adapter: Ecto.Adapters.Postgres
end
