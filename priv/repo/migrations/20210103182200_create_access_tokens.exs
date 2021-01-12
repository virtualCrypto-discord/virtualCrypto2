defmodule VirtualCrypto.Repo.Migrations.CreateAccessTokens do
  use Ecto.Migration

  def change do

    create table(:access_tokens) do
      add :grant_id, references(:grants, on_delete: :delete_all,on_update: :update_all)
      add :token,:string
      add :expires,:naive_datetime

      timestamps()
    end
    create unique_index(:access_tokens, [:id])
    create unique_index(:access_tokens, [:token])
    create index(:access_tokens, [:expires])

  end
end
