defmodule VirtualCrypto.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:discord_users) do
      add :user_id, references(:users, on_delete: :nothing)
      add :discord_id, :bigint

      timestamps()
    end

    create unique_index(:discord_users, [:id])
    create unique_index(:discord_users, [:user_id])
    create unique_index(:discord_users, [:discord_id])
  end
end
