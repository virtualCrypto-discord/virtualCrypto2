defmodule VirtualCrypto.Money.DepositAgreement do
  use Ecto.Schema
  @type status_t() :: String.t()
  schema "deposit_agreements" do
    field :contractor_id, :integer
    field :currency_id, :integer
    field :amount, :integer

    timestamps()
  end

  @doc false
  def changeset(contract, _attrs) do
    contract
  end
end
