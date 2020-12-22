defmodule VirtualCrypto.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add :amount, :integer
      add :status, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :money_id, references(:info, on_delete: :nothing)

      timestamps()
    end

    create index(:assets, [:user_id])
    create index(:assets, [:money_id])
  end
end
