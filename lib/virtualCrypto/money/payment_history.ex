defmodule VirtualCrypto.Money.PaymentHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "money_payment_historys" do
    field :amount, :integer
    field :time, :time
    field :sender_id, :id
    field :receiver_id, :id
    field :money_id, :id

    timestamps()
  end

  @doc false
  def changeset(payment_history, attrs) do
    payment_history
    |> cast(attrs, [:amount, :time])
    |> validate_required([:amount, :time])
  end
end
