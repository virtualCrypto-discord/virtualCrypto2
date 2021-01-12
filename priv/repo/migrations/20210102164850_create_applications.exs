defmodule VirtualCrypto.Repo.Migrations.CreateApplication do
  use Ecto.Migration

  def change do
    execute("create type openid_connect_response_types as enum ('code')")
    execute("create type openid_connect_grant_types as enum ('unbound_authorization_code','authorization_code','refresh_token')")
    execute("create type openid_connect_application_type as enum ('native','web')")

    create table(:applications) do
      add :status, :integer
      add :client_id, :uuid
      add :client_secret,:string
      add :response_types, {:array,  :openid_connect_response_types}, default: ["code"]
      add :grant_types, {:array,  :openid_connect_grant_types}, default: ["authorization_code"]
      add :application_type, :openid_connect_application_type, default: "web"
      add :client_name, :string, null: true
      add :client_uri, :string, null: true
      add :logo_uri, :string, null: true
      add :owner_discord_id, :bigint
      add :discord_support_server_invite_slug, :string, null: true
      timestamps()
    end
    create unique_index(:applications, [:id])
    create unique_index(:applications, [:client_id])

  end
end
