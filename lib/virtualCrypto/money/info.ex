defmodule VirtualCrypto.Money.Info do
  use Ecto.Schema
  import Ecto.Changeset

  schema "info" do
    field :guild_id, :integer
    field :name, :string
    field :pool_amount, :integer
    field :status, :integer
    field :unit, :string

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:name, :unit, :status, :guild_id, :pool_amount])
    |> validate_required([:name, :unit, :status, :guild_id, :pool_amount])
    |> unique_constraint(:unit)
    |> unique_constraint(:guild_id)
  end
end
