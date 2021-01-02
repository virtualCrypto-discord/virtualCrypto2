defmodule VirtualCrypto.Repo.Migrations.AddOwnerDiscordIdUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:applications, [:owner_discord_id])
  end
end
