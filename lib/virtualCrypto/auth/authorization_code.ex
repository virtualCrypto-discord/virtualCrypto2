defmodule VirtualCrypto.Auth.AuthorizationCode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "authorization_codes" do
    field :code, :string
    field :redirect_uri, :string
    field :application_id, :integer
    field :guild_id, :integer
    field :scopes, {:array, :string}
    field :expires, :naive_datetime
    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:code, :redirect_uri, :client_id, :guild_id])
    |> validate_required([:code, :guild_id])
    |> unique_constraint([:code])
  end
end
