defmodule VirtualCrypto.Money.InternalAction do
  alias VirtualCrypto.Repo
  import Ecto.Query
  alias VirtualCrypto.Money

  def get_money_by_unit(money_unit) do
    Money.Info
    |> where([m], m.unit == ^money_unit)
    |> Repo.one()
  end

  def get_money_by_name(name) do
    Repo.get_by(Money.Info, name: name)
  end

  defp get_asset_with_lock(user_id, money_id) do
    Money.Asset
    |> where([a], a.user_id == ^user_id and a.money_id == ^money_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  defp upsert_asset_amount(user_id, money_id, amount) do
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

  defp update_asset_amount(asset_id, amount) do
    Money.Asset
    |> where([a], a.id == ^asset_id)
    |> update([inc: [amount: ^amount]])
    |> Repo.update_all([])
  end

  defp insert_user_if_not_exits(user_id) do
    Repo.insert(%Money.User{id: user_id, status: 0}, on_conflict: :nothing)
  end

  defp get_money_by_guild_id_with_lock(guild_id) do
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

  defp update_pool_amount(money_id, amount) do
    Money.Info
    |> where([a], a.id == ^money_id)
    |> update([inc: [pool_amount: ^amount]])
    |> Repo.update_all([])
  end

  def pay(sender_id, receiver_id, amount, money_unit) when is_integer(amount) and amount >= 1 do
    # Get money info by unit.
    with money <- get_money_by_unit(money_unit),
         # Is money exits?
         {:money, true} <- {:money, money != nil},
         # Get sender asset by sender id and money id.
         sender_asset <- get_asset_with_lock(sender_id, money.id),
         # Is sender asset exsits?
         {:sender_asset, true} <- {:sender_asset, sender_asset != nil},
         # Has sender enough amount?
         {:sender_asset_amount, true} <- {:sender_asset_amount, sender_asset.amount >= amount},
         # Insert reciver user if not exists.
         {:ok, _} <- insert_user_if_not_exits(receiver_id),
         # Upsert receiver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, money.id, amount) do
      # Update sender amount.
      {:ok, update_asset_amount(sender_asset.id, -amount)}
    else
      {:money, false} -> {:error, :not_found_money}
      {:sender_asset, false} -> {:error, :not_found_sender_asset}
      {:sender_asset_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end

  def give(receiver_id, amount, guild_id) do
    # Get money info by guild.
    with money <- get_money_by_guild_id_with_lock(guild_id),
         # Is money exits?
         {:money, true} <- {:money, money != nil},
         # Check pool amount enough.
         {:pool_amount, true} <- {:pool_amount, money.pool_amount >= amount},
         # Insert reciver user if not exists.
         {:ok, _} <- insert_user_if_not_exits(receiver_id),
         # Update reciver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, money.id, amount) do
      # Update pool amount.
      {:ok,update_pool_amount(money.id, -amount)}
    else
      {:money, false} -> {:error, :not_found_money}
      {:pool_amount, false} -> {:error, :not_enough_pool_amount}
      err -> {:error, err}
    end
  end

  def create(guild, name, unit, pool_amount) do
    # Check duplicate guild.
    with {:guild, nil} <- {:guild, get_money_by_guild_id(guild)},
         # Check duplicate unit.
         {:unit, nil} <- {:unit, get_money_by_unit(unit)} do
      # Insert new money info.
      # This operation may occur serialization(If transaction isolation level serializable.) or constraint(If other transaction isolation level) error.
      Repo.insert(%Money.Info{
        guild_id: guild,
        pool_amount: pool_amount,
        name: name,
        status: 0,
        unit: unit
      })
    else
      {:guild, _} -> {:error, :guild}
      {:unit, _} -> {:error, :unit}
    end
  end

  def balance(user_id) do
    from asset in Money.Asset,
      join: info in Money.Info,
      on: asset.money_id == info.id,
      where: asset.user_id == ^user_id,
      select: {asset.amount, asset.status, info.name, info.unit, info.guild_id, info.status},
      order_by: info.unit
  end
end

defmodule VirtualCrypto.Money do
  alias VirtualCrypto.Repo
  alias Ecto.Multi

  def pay(kw) do
    Multi.new()
    |> Multi.run(:pay, fn  _,_ ->
      VirtualCrypto.Money.InternalAction.pay(
        Keyword.fetch!(kw, :sender),
        Keyword.fetch!(kw, :receiver),
        Keyword.fetch!(kw, :amount),
        Keyword.fetch!(kw, :unit)
      )
    end)
    |> Repo.transaction()
  end

  def give(kw) do
    Multi.new()
    |> Multi.run(:give, fn  _,_ ->
      VirtualCrypto.Money.InternalAction.give(
        Keyword.fetch!(kw, :receiver),
        Keyword.fetch!(kw, :amount),
        Keyword.fetch!(kw, :guild)
      )
    end)
    |> Repo.transaction()
  end

  defp _create(_, _, _, _, 0) do
  end

  defp _create(guild, name, unit, pool_amount, retry) do
    case Multi.new()
         |> Multi.run(:create, fn _,_ ->
           VirtualCrypto.Money.InternalAction.create(guild, name, unit, pool_amount)
         end)
         |> Repo.transaction() do
      {:ok, _} -> {:ok}
      {:error, :guild} -> {:error, :guild}
      {:error, :unit} -> {:error, :unit}
      {:error, _} -> _create(guild, name, unit, pool_amount, retry - 1)
    end
  end

  def create(kw) do
    _create(
      Keyword.fetch!(kw, :guild),
      Keyword.fetch!(kw, :name),
      Keyword.fetch!(kw, :unit),
      Keyword.get(kw, :pool_amount, 0),
      Keyword.get(kw, :retry_count, 5)
    )
  end

  def balance(kw) do
    Repo.all(VirtualCrypto.Money.InternalAction.balance(Keyword.fetch!(kw, :user)))
  end

  def info(kw) do
    with {:name, nil} <- {:name, Keyword.get(kw, :name)},
         {:unit, nil} <- {:unit, Keyword.get(kw, :unit)} do
      VirtualCrypto.Money.InternalAction.get_money_by_guild_id(Keyword.fetch!(kw, :guild))
    else
      {:name, name} -> VirtualCrypto.Money.InternalAction.get_money_by_name(name)
      {:unit, unit} -> VirtualCrypto.Money.InternalAction.get_money_by_unit(unit)
    end
  end
end
