defmodule VirtualCrypto.Repo.Migrations.CreateInfo do
  use Ecto.Migration

  def change do
    create table(:info) do
      add :name, :string
      add :unit, :string
      add :status, :integer
      add :guild_id, :integer
      add :pool_amount, :integer

      timestamps()
    end

    create unique_index(:info, [:unit])
    create unique_index(:info, [:guild_id])
  end
end
