defmodule VirtualCrypto.Repo.Migrations.CreateRedirectUris do
  use Ecto.Migration

  def change do
    create table(:redirect_uris) do
      add :application_id, references(:applications, on_delete: :delete_all)
      add :redirect_uri, :string
      timestamps()
    end

    create unique_index(:redirect_uris, [:application_id, :redirect_uri])
  end
end
