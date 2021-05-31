defmodule VirtualCrypto.Money.GivenHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "currency_given_histories" do
    field :amount, :integer
    field :time, :naive_datetime
    field :receiver_id, :id
    field :currency_id, :id

    timestamps()
  end

  @doc false
  def changeset(given_history, attrs) do
    given_history
    |> cast(attrs, [:amount, :naive_datetime])
    |> validate_required([:amount, :naive_datetime])
  end
end
