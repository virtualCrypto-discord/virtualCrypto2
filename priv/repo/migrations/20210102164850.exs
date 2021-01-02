defmodule VirtualCrypto.Repo.Migrations.CreateUsers2 do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :discord_id, :bigint, null: true
      add :application_id, references(:applications, on_delete: :nothing), null: true
      add :status, :integer

      timestamps()
    end
    create unique_index(:users, [:discord_id])
    create unique_index(:users, [:application_id])
  end
end
