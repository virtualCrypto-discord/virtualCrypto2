defmodule VirtualCrypto.Repo.Migrations.CreatePaymentIdempotency do
  use Ecto.Migration

  def change do
    create table(:payments_idempotency) do
      add(:user_id, references(:users), null: false)
      add(:idempotency_key, :string, null: false)
      add(:expires, :naive_datetime, null: false)
      add(:http_status, :integer)
      add(:body, :map)

      timestamps()
    end

    create(unique_index(:payments_idempotency, [:id]))
    create(unique_index(:payments_idempotency, [:idempotency_key, :user_id]))
  end
end
