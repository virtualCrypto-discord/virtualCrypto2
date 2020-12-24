defmodule VirtualCrypto.Repo.Migrations.AddUserMoneyIndexToAssets do
  use Ecto.Migration

  def change do
    create unique_index(:info, :name)
  end
end
