defmodule VirtualCrypto.Money.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :discord_id, :integer,null: true
    field :application_id, :integer,null: true
    field :status, :integer

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:status,:discord_id,:application_id])
    |> validate_required([:status])
    |> unique_constraint(:discord_id)
    |> unique_constraint(:application_id)
  end
end
