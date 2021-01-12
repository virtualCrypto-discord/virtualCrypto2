defmodule VirtualCrypto.Auth.RedirectUri do
  use Ecto.Schema
  import Ecto.Changeset

  schema "redirect_uris" do
    field :application_id, :integer
    field :redirect_uri, :string
    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:application_id, :redirect_uri])
    |> validate_required([:application_id, :redirect_uri])
  end
end
