defmodule VirtualCryptoLegacyIssuer.LegacyIssuer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "legacy_issuer" do
    field :currency_id, :integer
    field :guild_id, :integer
    field :pool_amount, :integer
    timestamps()
  end

  @doc false
  def changeset(currency, attrs) do
    currency
    |> cast(attrs, [:currency_id, :guild_id, :pool_amount])
    |> validate_required([:currency_id, :guild_id, :pool_amount])
    |> unique_constraint(:guild_id)
    |> unique_constraint(:currency_id)
  end
end
