defmodule VirtualCrypto.Repo.Migrations.CreateRefreshTokens do
  use Ecto.Migration

  def change do

    create table(:refresh_tokens) do
      add :grant_id, references(:grants, on_delete: :delete_all,on_update: :update_all)
      add :token,:string
      add :expires,:naive_datetime

      timestamps()
    end
    create unique_index(:refresh_tokens, [:id])
    create unique_index(:refresh_tokens, [:token])
    create unique_index(:refresh_tokens, [:grant_id])
    create index(:refresh_tokens, [:expires])

  end
end
