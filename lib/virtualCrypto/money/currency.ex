defmodule VirtualCrypto.Money.Currency do
  use Ecto.Schema
  import Ecto.Changeset

  schema "currencies" do
    field :name, :string
    field :unit, :string
    timestamps()
  end

  @doc false
  def changeset(currency, attrs) do
    currency
    |> cast(attrs, [:name, :unit])
    |> validate_required([:name, :unit])
    |> unique_constraint(:unit)
    |> unique_constraint(:name)
  end
end
