defmodule VirtualCrypto.Repo.Migrations.CreateContracts do
  use Ecto.Migration

  def change do
    create table(:contracts) do
      add(:intermediary_id, references(:applications, on_delete: :restrict), null: false)

      timestamps()
    end

    create table(:contractors) do
      add(:contract_id, references(:contracts, on_delete: :restrict), null: false)
      add(:user_id, references(:users, on_delete: :restrict), null: false)
      add(:status, :string, null: false)

      timestamps()
    end

    create table(:deposit_agreements) do
      add(:contractor_id, references(:contracts, on_delete: :restrict), null: false)
      add(:currency_id, references(:users, on_delete: :restrict), null: false)
      add(:deposit_amount, :bigint, null: false)
      add(:executed_amount, :bigint, null: false)

      timestamps()
    end

    alter table(:users) do
      add :contract_id, references(:contracts, on_delete: :restrict), null: true
    end

    create unique_index(:contracts, [:intermediary_id])
    create unique_index(:contractors, [:contract_id, :user_id])
    create index(:contractors, [:user_id])
    create unique_index(:deposit_agreements, [:contractor_id, :currency_id])

    create unique_index(:users, [:contract_id])
  end
end
