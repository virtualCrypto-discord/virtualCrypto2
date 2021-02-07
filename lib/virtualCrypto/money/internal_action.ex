defmodule VirtualCrypto.Money.InternalAction do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  alias VirtualCrypto.User.User
  import VirtualCrypto.User
  import Ecto.Query

  defguard is_non_neg_integer(v) when is_integer(v) and v >= 0
  defguard is_positive_integer(v) when is_integer(v) and v > 0

  def pay(sender_id, receiver_discord_id, amount, money_unit)
      when is_positive_integer(amount) do
    # Get money info by unit.
    with money <- get_money_by_unit(money_unit),
         # Is money exits?
         {:money, true} <- {:money, money != nil},
         # Get sender id.
         # Get sender asset by sender id and money id.
         sender_asset <- get_asset_with_lock(sender_id, money.id),
         # Is sender asset exsits?
         {:sender_asset, true} <- {:sender_asset, sender_asset != nil},
         # Has sender enough amount?
         {:sender_asset_amount, true} <- {:sender_asset_amount, sender_asset.amount >= amount},
         # Insert reciver user if not exists.
         {:ok, %User{id: receiver_id}} <- insert_user_if_not_exists(receiver_discord_id),
         # Upsert receiver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, money.id, amount),
         # Update sender amount.
         {:ok, _} <- update_asset_amount(sender_asset.id, -amount),
         {:ok, _} <-
           Repo.insert(%VirtualCrypto.Money.PaymentHistory{
             amount: amount,
             money_id: money.id,
             receiver_id: receiver_id,
             sender_id: sender_id,
             time: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
           }) do
      {:ok, nil}
    else
      {:money, false} -> {:error, :not_found_money}
      {:sender_asset, false} -> {:error, :not_found_sender_asset}
      {:sender_asset_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end

  def pay(_sender_id, _receiver_discord_id, _amount, _money_unit) do
    {:error, :invalid_amount}
  end

  def get_money_by_unit(money_unit) do
    Money.Info
    |> where([m], m.unit == ^money_unit)
    |> Repo.one()
  end

  def get_money_by_name(name) do
    Repo.get_by(Money.Info, name: name)
  end

  def get_asset_with_lock(user_id, money_id) do
    Money.Asset
    |> where([a], a.user_id == ^user_id and a.money_id == ^money_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  def upsert_asset_amount(user_id, money_id, amount) do
    Repo.insert(
      %Money.Asset{
        user_id: user_id,
        money_id: money_id,
        amount: amount,
        status: 0
      },
      on_conflict: [inc: [amount: amount]],
      conflict_target: [:user_id, :money_id]
    )
  end

  def update_asset_amount(asset_id, amount) do
    {1, nil} =
      Money.Asset
      |> where([a], a.id == ^asset_id)
      |> update(inc: [amount: ^amount])
      |> Repo.update_all([])

    {:ok, nil}
  end

  def get_money_by_guild_id_with_lock(guild_id) do
    Money.Info
    |> where([m], m.guild_id == ^guild_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  def get_money_by_guild_id(guild_id) do
    Money.Info
    |> where([m], m.guild_id == ^guild_id)
    |> Repo.one()
  end

  def get_money_by_id(id) do
    Money.Info
    |> where([m], m.id == ^id)
    |> Repo.one()
  end

  def update_pool_amount(money_id, amount) do
    {1, nil} =
      Money.Info
      |> where([a], a.id == ^money_id)
      |> update(inc: [pool_amount: ^amount])
      |> Repo.update_all([])

    {:ok, nil}
  end

  def info(:guild, guild_id) do
    from asset in Money.Asset,
      join: info in Money.Info,
      on: asset.money_id == info.id,
      where: info.guild_id == ^guild_id,
      group_by: info.id,
      select:
        {sum(asset.amount), info.name, info.unit, info.guild_id, info.status, info.pool_amount}
  end

  def info(:name, name) do
    from asset in Money.Asset,
      join: info in Money.Info,
      on: asset.money_id == info.id,
      where: info.name == ^name,
      group_by: info.id,
      select:
        {sum(asset.amount), info.name, info.unit, info.guild_id, info.status, info.pool_amount}
  end

  def info(:unit, unit) do
    from asset in Money.Asset,
      join: info in Money.Info,
      on: asset.money_id == info.id,
      where: info.unit == ^unit,
      group_by: info.id,
      select:
        {sum(asset.amount), info.name, info.unit, info.guild_id, info.status, info.pool_amount}
  end

  @reset_pool_amount """
  UPDATE info
  SET pool_amount = (CASE
    WHEN temp.pool_amount<5 THEN 5
    ELSE temp.pool_amount
  END)
  FROM (SELECT money_id,(SUM(amount)+199)/200 AS pool_amount FROM assets GROUP BY money_id) AS temp
  WHERE temp.money_id = info.id
  ;
  """
  def reset_pool_amount() do
    Ecto.Adapters.SQL.query!(Repo, @reset_pool_amount)
  end

  def get_claim_by_id(id) do
    query =
      from claim in Money.Claim,
        join: info in Money.Info,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.money_info_id == info.id and
            claim.claimant_user_id == claimant.id,
        where: claim.id == ^id,
        select: {claim, info, claimant, payer}

    query |> Repo.one()
  end

  def create_claim(claimant_user_id, payer_user_id, unit, amount)
      when is_positive_integer(amount) do
    case Money.Info |> where([i], i.unit == ^unit) |> Repo.one() do
      nil ->
        {:error, :money_not_found}

      info ->
        %Money.Claim{
          amount: amount,
          status: "pending",
          claimant_user_id: claimant_user_id,
          payer_user_id: payer_user_id,
          money_info_id: info.id
        }
        |> Repo.insert()
    end
  end

  def create_claim(_claimant_user_id, _payer_user_id, _unit, _amount) do
    {:error, :invalid_amount}
  end

  def create(guild, name, unit, creator_discord_id, creator_amount, pool_amount)
      when is_non_neg_integer(pool_amount) and is_non_neg_integer(creator_amount) do
    # Check duplicate guild.
    with {:guild, nil} <- {:guild, get_money_by_guild_id(guild)},
         # Check duplicate unit.
         {:unit, nil} <- {:unit, get_money_by_unit(unit)},
         {:name, nil} <- {:name, get_money_by_name(name)},
         # Create creator user
         {:ok, %User{id: creator_id}} <- insert_user_if_not_exists(creator_discord_id) do
      # Insert new money info.
      # This operation may occur serialization(If transaction isolation level serializable.) or constraint(If other transaction isolation level) error.
      {:ok, info} =
        Repo.insert(
          %Money.Info{
            guild_id: guild,
            pool_amount: pool_amount,
            name: name,
            status: 0,
            unit: unit
          },
          returning: true
        )

      # Insert creator asset.
      # Always success.
      Repo.insert(%Money.Asset{
        amount: creator_amount,
        status: 0,
        user_id: creator_id,
        money_id: info.id
      })
    else
      {:guild, _} -> {:error, :guild}
      {:unit, _} -> {:error, :unit}
      {:name, _} -> {:error, :name}
      err -> {:error, err}
    end
  end

  def create(_guild, _name, _unit, _creator_discord_id, _creator_amount, _pool_amount) do
    {:error, :invalid_amount}
  end

  def give(receiver_discord_id, amount, guild_id)
      when is_positive_integer(amount) do
    # Get money info by guild.
    with money <- get_money_by_guild_id_with_lock(guild_id),
         # Is money exits?
         {:money, true} <- {:money, money != nil},
         # Check pool amount enough.
         {:pool_amount, true} <- {:pool_amount, money.pool_amount >= amount},
         # Insert reciver user if not exists.
         {:ok, %User{id: receiver_id}} <- insert_user_if_not_exists(receiver_discord_id),
         # Update reciver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, money.id, amount),
         # Update pool amount.
         {:ok, _} <- update_pool_amount(money.id, -amount),
         {:ok, _} <-
           Repo.insert(%VirtualCrypto.Money.GivenHistory{
             amount: amount,
             money_id: money.id,
             time: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
             receiver_id: receiver_id
           }) do
      {:ok, nil}
    else
      {:money, false} -> {:error, :not_found_money}
      {:pool_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end

  def give(_receiver_discord_id, _amount, _guild_id) do
    {:error, :invalid_amount}
  end

  def get_sent_claim(id, user_id) do
    query =
      from claim in Money.Claim,
        join: info in Money.Info,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.money_info_id == info.id and
            claim.claimant_user_id == claimant.id,
        where: claim.id == ^id and claim.claimant_user_id == ^user_id,
        select: {claim, info, claimant, payer}

    query |> Repo.one()
  end

  def get_received_claim(id, user_id) do
    query =
      from claim in Money.Claim,
        join: info in Money.Info,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.money_info_id == info.id and
            claim.claimant_user_id == claimant.id,
        where: claim.id == ^id and claim.payer_user_id == ^user_id,
        select: {claim, info, claimant, payer}

    query |> Repo.one()
  end

  def get_sent_claims(user_id) do
    query =
      from claim in Money.Claim,
        join: info in Money.Info,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.money_info_id == info.id and
            claim.claimant_user_id == claimant.id,
        where: claim.claimant_user_id == ^user_id,
        select: {claim, info, claimant, payer}

    query |> Repo.all()
  end

  def get_received_claims(user_id) do
    query =
      from claim in Money.Claim,
        join: info in Money.Info,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.money_info_id == info.id and
            claim.claimant_user_id == claimant.id,
        where: claim.payer_user_id == ^user_id,
        select: {claim, info, claimant, payer}

    query |> Repo.all()
  end

  def get_claims(user_id) do
    sent_claims = get_sent_claims(user_id)
    received_claims = get_received_claims(user_id)
    {sent_claims, received_claims}
  end

  defp update_claim_status(id, new_status) do
    result =
      Money.Claim
      |> where([c], c.id == ^id and c.status == "pending")
      |> update(set: [status: ^new_status])
      |> select([c], {c})
      |> Repo.update_all([])

    case result do
      {0, _} -> {:error, :not_found}
      {1, [{c}]} -> {:ok, c}
    end
  end

  def approve_claim(id) do
    update_claim_status(id, "approved")
  end

  def deny_claim(id) do
    update_claim_status(id, "denied")
  end

  def cancel_claim(id) do
    update_claim_status(id, "canceled")
  end
end
