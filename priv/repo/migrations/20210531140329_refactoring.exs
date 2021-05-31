defmodule VirtualCrypto.Repo.Migrations.Refactoring20212303 do
  use Ecto.Migration

  def change do
    rename table("info"), to: table("currencies")
    rename table("assets"), :money_id, to: :currency_id
    rename table("claims"), :money_info_id, to: :currency_id
    rename table("money_given_historys"), to: table("currency_given_histories")
    rename table("currency_given_histories"), :money_id, to: :currency_id
    rename table("money_payment_historys"), to: table("currency_payment_histories")
    rename table("currency_payment_histories"), :money_id, to: :currency_id
  end
end
