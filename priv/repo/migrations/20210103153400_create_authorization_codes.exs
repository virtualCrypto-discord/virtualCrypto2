defmodule VirtualCrypto.Repo.Migrations.CreateAuthorizationCodes do
  use Ecto.Migration

  def change do
    execute("create type virtual_crypto_scope_type as enum ('openid')")

    create table(:authorization_codes) do
      add :code, :string
      add :redirect_uri, :string

      add :application_id,
          references(:applications, on_delete: :delete_all, on_update: :update_all)

      add :guild_id, :bigint
      add :scopes, {:array, :virtual_crypto_scope_type}
      add :expires, :naive_datetime
      timestamps()
    end

    create unique_index(:authorization_codes, [:id])
    create unique_index(:authorization_codes, [:code])
    create index(:authorization_codes, [:expires])
  end
end
