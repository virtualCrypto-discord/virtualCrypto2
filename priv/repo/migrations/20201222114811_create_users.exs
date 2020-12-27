defmodule VirtualCrypto.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :status, :integer

      timestamps()
    end
    create unique_index(:users, [:id])
  end
end
