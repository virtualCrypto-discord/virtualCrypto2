defmodule VirtualCrypto.Repo.Migrations.CreateClaims do
  use Ecto.Migration

  def change do
    create table(:claims) do
      add :amount, :integer
      add :message, :text
      add :status, :integer
      add :claimant_user, references(:users, on_delete: :nothing)
      add :payer_user, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:claims, [:claimant_user])
    create index(:claims, [:payer_user])
  end
end
