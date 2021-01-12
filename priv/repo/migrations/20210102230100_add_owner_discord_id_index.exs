defmodule VirtualCrypto.Repo.Migrations.AddOwnerDiscordIdIndex do
  use Ecto.Migration

  def change do
    create index(:applications, [:owner_discord_id])
  end
end
