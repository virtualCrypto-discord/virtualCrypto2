defmodule VirtualCrypto.Repo.Migrations.FixDiscordUsers do
  use Ecto.Migration

  def change do
    alter table(:discord_users) do
      modify :discord_user_id, references(:users, column: :discord_id)
      add :expires, :naive_datetime
    end

    execute """
    UPDATE discord_users SET expires = updated_at + interval '7 days' WHERE expires IS NULL
    """
  end
end
