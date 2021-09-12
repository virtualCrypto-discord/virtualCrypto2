defmodule VirtualCrypto.Money.ClaimMetadata do
  use Ecto.Schema
  import Ecto.Changeset
  @type status_t() :: String.t()
  schema "claim_metadata" do
    field :claim_id, :integer
    field :claimant_user_id, :integer
    field :payer_user_id, :integer
    field :owner_user_id, :integer
    field :metadata, :map
  end

  @doc false
  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:claim_id, :claimant_user_id, :payer_user_id, :owner_user_id, :metadata])
    |> validate_required([
      :claim_id,
      :claimant_user_id,
      :payer_user_id,
      :owner_user_id,
      :metadata
    ])
  end
end
