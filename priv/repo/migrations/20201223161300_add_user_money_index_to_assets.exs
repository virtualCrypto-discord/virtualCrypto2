defmodule VirtualCrypto.Repo.Migrations.AddUserMoneyIndexToAssets do
  use Ecto.Migration

  def change do
    create unique_index(:assets, [:user_id,:money_id])
  end
end
