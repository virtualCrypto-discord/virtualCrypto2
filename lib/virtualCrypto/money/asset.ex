defmodule VirtualCrypto.Money.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assets" do
    field :amount, :integer
    field :user_id, :id
    field :money_id, :id

    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
    |> unique_constraint([:user_id, :money_id])
  end
end
