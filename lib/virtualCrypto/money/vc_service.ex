defmodule VirtualCrypto.Money.VCService do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  import Ecto.Query
  alias VirtualCrypto.Money.InternalAction, as: Action

  def pay(
        sender_vc_id,
        receiver_discord_id,
        amount,
        money_unit
      ) do
    Action.pay(sender_vc_id, receiver_discord_id, amount, money_unit)
  end

  def balance(user_id) do
    q =
      from asset in Money.Asset,
        join: info in Money.Info,
        on: asset.money_id == info.id,
        on: asset.user_id == ^user_id,
        select: {asset.amount, asset.status, info.name, info.unit, info.guild_id, info.status},
        order_by: info.unit

    Repo.all(q)
  end

  def get_sent_claim(id, user_id) do
    Action.get_sent_claim(id, user_id)
  end

  def get_received_claim(id, user_id) do
    Action.get_received_claim(id, user_id)
  end

  def get_claims(user_id) do
    Action.get_claims(user_id)
  end

  def approve_claim(id, user_id) do
    Action.approve_claim(id, user_id)
  end

  def deny_claim(id, user_id) do
    Action.deny_claim(id, user_id)
  end

  def cancel_claim(id, user_id) do
    Action.cancel_claim(id, user_id)
  end

  def create_claim(claimant_id, payer_discord_user_id, unit, amount) do
    Action.create_claim(
      claimant_id,
      VirtualCrypto.User.insert_user_if_not_exists(payer_discord_user_id).id,
      unit,
      amount
    )
  end
end
