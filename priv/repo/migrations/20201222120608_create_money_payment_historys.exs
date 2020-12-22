defmodule VirtualCrypto.Repo.Migrations.CreateMoneyPaymentHistorys do
  use Ecto.Migration

  def change do
    create table(:money_payment_historys) do
      add :amount, :integer
      add :time, :time
      add :sender_id, references(:users, on_delete: :nothing)
      add :receiver_id, references(:users, on_delete: :nothing)
      add :money_id, references(:info, on_delete: :nothing)

      timestamps()
    end

    create index(:money_payment_historys, [:sender_id])
    create index(:money_payment_historys, [:receiver_id])
    create index(:money_payment_historys, [:money_id])
  end
end
