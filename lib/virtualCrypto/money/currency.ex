defmodule VirtualCrypto.Money.Currency do
  use Ecto.Schema
  import Ecto.Changeset

  schema "currencies" do
    field :guild_id, :integer
    field :name, :string
    field :pool_amount, :integer
    field :unit, :string
    timestamps()
  end

  @doc false
  def changeset(currency, attrs) do
    currency
    |> cast(attrs, [:name, :unit, :status, :guild_id, :pool_amount])
    |> validate_required([:name, :unit, :status, :guild_id, :pool_amount])
    |> unique_constraint(:unit)
    |> unique_constraint(:guild_id)
    |> unique_constraint(:name)
  end
end
