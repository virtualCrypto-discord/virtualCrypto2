defmodule VirtualCrypto.Auth.DiscordUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "discord_users" do
    field :discord_user_id, :integer
    field :refresh_token, :string
    field :token, :string

    timestamps()
  end

  @doc false
  def changeset(discord_user, attrs) do
    discord_user
    |> cast(attrs, [:discord_user_id, :refresh_token, :token])
    |> validate_required([:discord_user_id, :refresh_token, :token])
    |> unique_constraint([:discord_user_id])
  end
end
