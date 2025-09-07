defmodule VirtualCrypto.Money.DepositAgreement do
  use Ecto.Schema
  import Ecto.Changeset
  schema "deposit_agreements" do
    field :contractor_id, :integer
    field :currency_id, :integer
    field :deposit_amount, :integer
    field :executed_amount, :integer

    timestamps()
  end

  @doc false
  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [:executed_amount])
    |> validate_required([:executed_amount])
  end
end
