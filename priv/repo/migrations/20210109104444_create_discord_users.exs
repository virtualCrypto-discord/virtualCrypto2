defmodule VirtualCrypto.Repo.Migrations.CreateDiscordUsers do
  use Ecto.Migration

  def change do
    create table(:discord_users) do
      add :discord_user_id, :bigint
      add :refresh_token, :string
      add :token, :string

      timestamps()
    end

    create unique_index(:discord_users, [:discord_user_id])
    create index(:discord_users, [:token])
    create index(:discord_users, [:refresh_token])
  end
end
