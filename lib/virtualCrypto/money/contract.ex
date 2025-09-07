defmodule VirtualCrypto.Money.Contract do
  use Ecto.Schema
  @type status_t() :: String.t()
  schema "contracts" do
    field :intermediary_id, :integer

    timestamps()
  end

  @doc false
  def changeset(contract, _attrs) do
    contract
  end
end
