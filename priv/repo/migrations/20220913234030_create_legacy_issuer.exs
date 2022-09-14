defmodule VirtualCrypto.Repo.Migrations.CreateLegacyIssuer do
  use Ecto.Migration

  def change do
    create table(:legacy_issuer) do
      add :currency_id, references(:currencies, on_delete: :nothing)
      add :guild_id, :bigint
      add :pool_amount, :integer
      timestamps()
    end

    create unique_index(:legacy_issuer, [:currency_id])
    create unique_index(:legacy_issuer, [:guild_id])
  end
end
