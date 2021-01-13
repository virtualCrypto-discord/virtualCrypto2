defmodule VirtualCrypto.Money.Claim do
  use Ecto.Schema
  import Ecto.Changeset

  schema "claims" do
    field :amount, :integer
    field :message, :string
    field :status, :string
    field :claimant_user, :id
    field :payer_user, :id

    timestamps()
  end

  @doc false
  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:amount, :message, :status])
    |> validate_required([:amount, :message, :status])
  end
end
