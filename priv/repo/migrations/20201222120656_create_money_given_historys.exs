defmodule VirtualCrypto.Repo.Migrations.CreateMoneyGivenHistorys do
  use Ecto.Migration

  def change do
    create table(:money_given_historys) do
      add :amount, :integer
      add :time, :time
      add :receiver_id, references(:users, on_delete: :nothing)
      add :money_id, references(:info, on_delete: :nothing)

      timestamps()
    end

    create index(:money_given_historys, [:receiver_id])
    create index(:money_given_historys, [:money_id])
  end
end
