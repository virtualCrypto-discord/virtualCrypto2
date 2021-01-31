defmodule VirtualCrypto.Repo.Migrations.CreateUserAccessTokens do
  use Ecto.Migration

  def change do
    create table(:user_access_tokens) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :token_id, :uuid
      add :expires, :naive_datetime
      timestamps()
    end

    create unique_index(:user_access_tokens,:token_id)
    create index(:user_access_tokens,:expires)
    create index(:user_access_tokens,:user_id)
  end
end
