defmodule VirtualCrypto.Money.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assets" do
    field :amount, :integer
    field :status, :integer
    field :user_id, :id
    field :money_id, :id

    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:amount, :status])
    |> validate_required([:amount, :status])
  end
end
