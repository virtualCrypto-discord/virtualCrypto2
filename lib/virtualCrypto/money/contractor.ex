defmodule VirtualCrypto.Money.Contractor do
  use Ecto.Schema
  import Ecto.Changeset
  @type status_t() :: String.t()
  schema "contractors" do
    field :contract_id, :integer
    field :user_id, :integer
    field :status, :string

    timestamps()
  end

  @doc false
  def changeset(contractor, attrs) do
    contractor
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
