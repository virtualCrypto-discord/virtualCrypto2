defmodule VirtualCrypto.Repo.Migrations.CreateGrantScopes do
  use Ecto.Migration

  def change do

    create table(:grant_scopes) do
      add :grant_id, references(:grants, on_delete: :delete_all,on_update: :update_all)
      add :scope,:virtual_crypto_scope_type
      timestamps()
    end
    create unique_index(:grant_scopes, [:id])
    create unique_index(:grant_scopes, [:grant_id,:scope])
  end
end
