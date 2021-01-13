defmodule VirtualCrypto.Repo.Migrations.CreateClaims do
  use Ecto.Migration

  def change do
    execute("create type virtual_crypto_claim_status as enum ('pending', 'approve', 'deny')")

    create table(:claims) do
      add :amount, :integer
      add :message, :text
      add :status, :virtual_crypto_claim_status
      add :claimant_user, references(:users, on_delete: :nothing)
      add :payer_user, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:claims, [:claimant_user])
    create index(:claims, [:payer_user])
  end
end
