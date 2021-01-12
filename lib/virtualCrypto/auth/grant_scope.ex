defmodule VirtualCrypto.Auth.GrantScope do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grant_scopes" do
    field :grant_id, :integer
    field :scope, :string
    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:grant_id, :scope])
    |> validate_required([:grant_id, :scope])
    |> unique_constraint([:grant_id, :scope])
  end
end
