defmodule VirtualCrypto.Repo.Migrations.ChangeUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :discord_id, :bigint, null: true
      add :application_id, references(:applications, on_delete: :nothing), null: true

    end
    create unique_index(:users, [:discord_id])
    create unique_index(:users, [:application_id])
  end
end
