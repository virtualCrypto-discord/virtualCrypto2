defmodule VirtualCrypto.Repo.Migrations.AddConstraintsToAmounts do
  use Ecto.Migration

  def change do
    create constraint("info", "pool_amount_must_not_be_negative", check: "pool_amount >= 0")
    create constraint("assets", "amount_must_not_be_negative", check: "amount >= 0")

  end
end
