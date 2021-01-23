defmodule VirtualCrypto.Repo.Migrations.DatabaseHasTokenIdInsteadOfWholeToken do
  use Ecto.Migration

  def change do
    alter table(:access_tokens) do
      remove :token
      add :token_id, :uuid
    end

    alter table(:refresh_tokens) do
      remove :token
      add :token_id, :uuid
    end

    create unique_index(:access_tokens, [:token_id])
    create unique_index(:refresh_tokens, [:token_id])
  end
end
