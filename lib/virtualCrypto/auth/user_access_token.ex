defmodule VirtualCrypto.Auth.UserAccessToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_access_tokens" do
    field :user_id, :integer
    field :expires, :naive_datetime
    field :token_id, Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(user_access_token, attrs) do
    user_access_token
    |> cast(attrs, [:token_id, :expires, :user_id])
    |> validate_required([:token_id, :expires, :user_id])
    |> unique_constraint([:token_id])
  end
end
