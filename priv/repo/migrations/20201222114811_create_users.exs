defmodule VirtualCrypto.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :status, :integer

      timestamps()
    end

    create unique_index(:users, [:id])
  end
end
