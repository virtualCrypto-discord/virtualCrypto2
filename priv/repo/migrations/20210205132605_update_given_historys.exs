defmodule VirtualCrypto.Repo.Migrations.UpdateGivenHistorys do
  use Ecto.Migration

  def change do
    alter table(:money_given_historys) do
      remove :time
      add :time, :naive_datetime
    end
  end
end
