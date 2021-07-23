defmodule VirtualCrypto.Money.Claim do
  use Ecto.Schema
  import Ecto.Changeset
  @type status_t() :: String.t()
  schema "claims" do
    field :amount, :integer
    field :status, :string
    field :claimant_user_id, :integer
    field :payer_user_id, :integer
    field :currency_id, :integer

    timestamps()
  end

  @doc false
  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:amount, :status])
    |> validate_required([:amount, :status])
  end
end
