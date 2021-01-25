defmodule VirtualCrypto.Repo.Migrations.CreateClaims do
  use Ecto.Migration

  def change do
    execute(
      "create type virtual_crypto_claim_status as enum ('pending', 'approved', 'denied', 'canceled')"
    )

    create table(:claims) do
      add :amount, :integer
      add :status, :virtual_crypto_claim_status
      add :claimant_user_id, :bigint
      add :payer_user_id, :bigint
      add :money_info_id, :bigint

      timestamps()
    end

    create index(:claims, [:claimant_user_id])
    create index(:claims, [:payer_user_id])
  end
end
