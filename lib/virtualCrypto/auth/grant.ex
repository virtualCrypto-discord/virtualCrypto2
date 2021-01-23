defmodule VirtualCrypto.Auth.Grant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grants" do
    field :application_id, :integer
    field :guild_id, :integer
    field :latest_code, :string
    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:application_id, :guild_id, :scopes, :latest_code])
    |> validate_required([:latest_code, :guild_id, :application_id, :scopes])
    |> unique_constraint([:latest_code])
    |> unique_constraint([:application_id, :guild_id])
  end
end
