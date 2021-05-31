defmodule VirtualCrypto.Money.PaymentHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "currency_payment_histories" do
    field :amount, :integer
    field :time, :naive_datetime
    field :sender_id, :id
    field :receiver_id, :id
    field :currency_id, :id

    timestamps()
  end

  @doc false
  def changeset(payment_history, attrs) do
    payment_history
    |> cast(attrs, [:amount, :naive_datetime])
    |> validate_required([:amount, :naive_datetime])
  end
end
