defmodule VirtualCrypto.User.User do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %VirtualCrypto.User.User{
          discord_id: binary() | nil,
          application_id: binary() | nil
        }

  schema "users" do
    field(:discord_id, :integer)
    field(:application_id, :integer)
    field(:status, :integer)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:status, :discord_id, :application_id])
    |> validate_required([:status])
    |> unique_constraint(:discord_id)
    |> unique_constraint(:application_id)
  end
end
