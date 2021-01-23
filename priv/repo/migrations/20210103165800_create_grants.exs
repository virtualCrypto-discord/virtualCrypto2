defmodule VirtualCrypto.Repo.Migrations.CreateGrants do
  use Ecto.Migration

  def change do
    create table(:grants) do
      add :application_id,
          references(:applications, on_delete: :delete_all, on_update: :update_all)

      add :guild_id, :bigint
      add :latest_code, :string
      timestamps()
    end

    create unique_index(:grants, [:id])
    create unique_index(:grants, [:application_id, :guild_id])
    create unique_index(:grants, [:latest_code])
  end
end
