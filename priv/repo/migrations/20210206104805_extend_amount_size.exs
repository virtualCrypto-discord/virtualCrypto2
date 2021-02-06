defmodule VirtualCrypto.Repo.Migrations.ExtendAmountSize do
  use Ecto.Migration

  def change do
    alter table(:info) do
      modify :pool_amount, :numeric, precision: 1000
    end

    alter table(:assets) do
      modify :amount, :numeric, precision: 1000
    end

    alter table(:money_payment_historys) do
      modify :amount, :numeric, precision: 1000
    end

    alter table(:money_given_historys) do
      modify :amount, :numeric, precision: 1000
    end

    alter table(:claims) do
      modify :amount, :numeric, precision: 1000
    end
  end
end
