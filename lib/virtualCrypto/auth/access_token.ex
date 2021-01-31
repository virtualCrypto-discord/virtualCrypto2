defmodule VirtualCrypto.Auth.AccessToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "access_tokens" do
    field :grant_id, :integer
    field :token_id, Ecto.UUID
    field :expires, :naive_datetime
    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:grant_id, :token, :expires])
    |> validate_required([:grant_id, :token_id, :expires])
    |> unique_constraint([:token_id])
  end
end
