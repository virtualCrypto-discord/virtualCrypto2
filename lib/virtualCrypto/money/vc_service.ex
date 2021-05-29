defmodule VirtualCrypto.Money.VCService do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  import Ecto.Query
  require VirtualCrypto.Money.InternalAction, as: Action

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
        select: {asset, info},
        order_by: info.unit

    Repo.all(q)
  end

  def get_sent_claim(id, user_id) do
    Action.get_sent_claim(id, user_id)
  end

  def get_sent_claim(id, user_id, status) do
    Action.get_sent_claim(id, user_id, status)
  end

  def get_received_claim(id, user_id) do
    Action.get_received_claim(id, user_id)
  end

  def get_received_claim(id, user_id, status) do
    Action.get_received_claim(id, user_id, status)
  end

  def get_claims(user_id) do
    Action.get_claims(user_id)
  end

  def get_claims(user_id, status) do
    Action.get_claims(user_id, status)
  end

  def get_claims(
        user_id,
        statuses,
        sr_filter,
        related_user_id,
        order_by,
        cursor,
        limit
      ) do
    Action.get_claims(user_id, statuses, sr_filter, related_user_id, order_by, cursor, limit)
  end

  def create_claim(claimant_id, payer_discord_user_id, unit, amount) do
    {:ok, payer} = VirtualCrypto.User.insert_user_if_not_exists(payer_discord_user_id)

    Action.create_claim(
      claimant_id,
      payer.id,
      unit,
      amount
    )
  end

  def equals?(user, user_id) do
    user.id == user_id
  end
end
