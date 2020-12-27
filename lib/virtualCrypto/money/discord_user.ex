defmodule VirtualCrypto.Money.DiscordUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "discord_users" do
    field :user_id, :id
    field :discord_id, :integer

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id,:discord_id])
    |> validate_required([:user_id,:discord_id])
    |> unique_constraint(:user_id)
    |> unique_constraint(:discord_id)
  end
end
