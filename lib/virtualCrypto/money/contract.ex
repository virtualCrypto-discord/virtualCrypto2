defmodule VirtualCrypto.Money.Contract do
  use Ecto.Schema
  import Ecto.Changeset
  @type status_t() :: String.t()
  schema "contracts" do
    field :intermediary_id, :integer
    field :status, :string

    timestamps()
  end

  @doc false
  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
