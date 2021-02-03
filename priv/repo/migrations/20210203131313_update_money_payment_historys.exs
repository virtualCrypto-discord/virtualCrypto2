defmodule VirtualCrypto.Repo.Migrations.UpdateMoneyPaymentHistorys do
  use Ecto.Migration

  def change do
    alter table(:money_payment_historys) do
      remove :time
      add :time, :naive_datetime
    end
  end
end
