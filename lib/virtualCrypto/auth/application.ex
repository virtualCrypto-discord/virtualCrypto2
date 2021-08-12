defmodule VirtualCrypto.Auth.Application do
  use Ecto.Schema
  import Ecto.Changeset

  schema "applications" do
    field :status, :integer
    field :client_id, Ecto.UUID
    field :client_secret, :string
    field :response_types, {:array, :string}
    field :grant_types, {:array, :string}
    field :application_type, :string
    field :client_name, :string
    field :client_uri, :string
    field :logo_uri, :string
    field :owner_discord_id, :integer
    field :discord_support_server_invite_slug, :string
    field :webhook_url, :string
    field :public_key, :binary
    field :private_key, :binary

    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [
      :status,
      :client_id,
      :client_secret,
      :response_types,
      :grant_types,
      :application_type,
      :client_name,
      :client_uri,
      :logo_uri,
      :owner_discord_id,
      :discord_support_server_invite_slug
    ])
    |> validate_required([:client_id, :client_secret, :status, :owner_discord_id])
    |> unique_constraint([:client_id])
  end
end
