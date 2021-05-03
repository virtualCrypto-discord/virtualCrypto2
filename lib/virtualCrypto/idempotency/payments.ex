defmodule VirtualCrypto.Idempotency.Payments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payments_idempotency" do
    field :user_id, :id
    field :idempotency_key, :string
    field :expires, :naive_datetime
    field :http_status, :integer
    field :body, :map
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:user_id, :idempotency_key, :expires, :http_status, :body])
    |> validate_required([:user_id, :idempotency_key, :expires])
    |> unique_constraint([:user_id, :idempotency_key])
  end
end
