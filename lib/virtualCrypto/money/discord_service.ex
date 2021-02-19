defmodule VirtualCrypto.Money.DiscordService do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  alias VirtualCrypto.User.User
  import Ecto.Query
  alias VirtualCrypto.Money.InternalAction, as: Action

  defp resolve(discord_id) do
    {:ok, user} = VirtualCrypto.User.insert_user_if_not_exists(discord_id)
    user.id
  end

  def pay(
        sender_discord_id,
        receiver_discord_id,
        amount,
        money_unit
      ) do
    Action.pay(resolve(sender_discord_id), receiver_discord_id, amount, money_unit)
  end

  def balance(discord_user_id) do
    q =
      from asset in Money.Asset,
        join: info in Money.Info,
        on: asset.money_id == info.id,
        join: users in User,
        on: users.discord_id == ^discord_user_id and users.id == asset.user_id,
        select: {asset.amount, asset.status, info.name, info.unit, info.guild_id, info.status},
        order_by: info.unit

    Repo.all(q)
  end

  def get_sent_claim(id, discord_user_id) do
    Action.get_sent_claim(id, resolve(discord_user_id))
  end

  def get_received_claim(id, discord_user_id) do
    Action.get_received_claim(id, resolve(discord_user_id))
  end

  def get_claims(discord_user_id) do
    Action.get_claims(resolve(discord_user_id))
  end

  def get_claims(discord_user_id, status) do
    Action.get_claims(resolve(discord_user_id), status)
  end

  def create_claim(claimant_discord_user_id, payer_discord_user_id, unit, amount) do
    Action.create_claim(
      resolve(claimant_discord_user_id),
      resolve(payer_discord_user_id),
      unit,
      amount
    )
  end
end
