defmodule VirtualCrypto.Money.GivenHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "money_given_historys" do
    field :amount, :integer
    field :time, :time
    field :receiver_id, :id
    field :money_id, :id

    timestamps()
  end

  @doc false
  def changeset(given_history, attrs) do
    given_history
    |> cast(attrs, [:amount, :time])
    |> validate_required([:amount, :time])
  end
end
