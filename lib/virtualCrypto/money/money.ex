defmodule VirtualCrypto.Money.InternalAction do
  alias VirtualCrypto.Repo
  import Ecto.Query
  alias VirtualCrypto.Money
  defguard is_non_neg_integer(v) when is_integer(v) and v >= 0
  defguard is_positive_integer(v) when is_integer(v) and v > 0

  def get_money_by_unit(money_unit) do
    Money.Info
    |> where([m], m.unit == ^money_unit)
    |> Repo.one()
  end

  def get_money_by_name(name) do
    Repo.get_by(Money.Info, name: name)
  end

  defp get_asset_with_lock(discord_user_id, money_id) do
    Money.Asset
    |> join(:inner, [a], d in Money.DiscordUser,
      on: d.user_id == a.user_id and d.discord_user_id == ^discord_user_id
    )
    |> where([a], a.money_id == ^money_id)
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
    |> update(inc: [amount: ^amount])
    |> Repo.update_all([])
  end

  # !! This may not work discord_user deletion !!
  def insert_user_if_not_exits(discord_user_id) do
    user = Repo.get_by(Money.DiscordUser, discord_id: discord_user_id)

    if user == nil do
      # Not found.
      Repo.query!("SAVEPOINT insert_user_if_not_exits;")
      # Insert user that will connect discord_user.
      {:ok, user} = Repo.insert(%Money.User{status: 0}, returning: true)
      # Insert discord_user connected inserted user.
      # This will conflict when race condition.
      case Repo.insert(%Money.DiscordUser{user_id: user.id, discord_id: discord_user_id},
             on_conflict: :nothing,
             returning: true
           ) do
        {:ok, %Money.DiscordUser{id: nil}} ->
          # Conflicted.
          # Rollback user insertion.
          Repo.query!(" ROLLBACK TO SAVEPOINT insert_user_if_not_exits;")
          # !! This may not work discord_user deletion !!
          discord_user = Repo.get_by(Money.DiscordUser, discord_id: discord_user_id)
          {:ok, discord_user.user_id}

        {:ok, _} ->
          # Not conflicted.
          {:ok, user.id}
      end
    else
      # Found
      {:ok, user.id}
    end
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
    |> update(inc: [pool_amount: ^amount])
    |> Repo.update_all([])
  end

  def pay(sender_discord_id, receiver_discord_id, amount, money_unit)
      when is_positive_integer(amount) do
    # Get money info by unit.
    with money <- get_money_by_unit(money_unit),
         # Is money exits?
         {:money, true} <- {:money, money != nil},
         # Get sender asset by sender id and money id.
         sender_asset <- get_asset_with_lock(sender_discord_id, money.id),
         # Is sender asset exsits?
         {:sender_asset, true} <- {:sender_asset, sender_asset != nil},
         # Has sender enough amount?
         {:sender_asset_amount, true} <- {:sender_asset_amount, sender_asset.amount >= amount},
         # Insert reciver user if not exists.
         {:ok, user_id} <- insert_user_if_not_exits(receiver_discord_id),
         # Upsert receiver amount.
         {:ok, _} <- upsert_asset_amount(user_id, money.id, amount) do
      # Update sender amount.
      {:ok, update_asset_amount(sender_asset.id, -amount)}
    else
      {:money, false} -> {:error, :not_found_money}
      {:sender_asset, false} -> {:error, :not_found_sender_asset}
      {:sender_asset_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
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
         {:ok, receiver_user_id} <- insert_user_if_not_exits(receiver_discord_id),
         # Update reciver amount.
         {:ok, _} <- upsert_asset_amount(receiver_user_id, money.id, amount) do
      # Update pool amount.
      {:ok, update_pool_amount(money.id, -amount)}
    else
      {:money, false} -> {:error, :not_found_money}
      {:pool_amount, false} -> {:error, :not_enough_pool_amount}
      err -> {:error, err}
    end
  end

  def create(guild, name, unit, creator, creator_amount, pool_amount)
      when is_non_neg_integer(pool_amount) and is_non_neg_integer(creator_amount) do
    # Check duplicate guild.
    with {:guild, nil} <- {:guild, get_money_by_guild_id(guild)},
         # Check duplicate unit.
         {:unit, nil} <- {:unit, get_money_by_unit(unit)},
         {:name, nil} <- {:name, get_money_by_name(name)} do
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
      Repo.insert!(%Money.Asset{
        amount: creator_amount,
        status: 0,
        user_id: creator,
        money_id: info.id
      })
    else
      {:guild, _} -> {:error, :guild}
      {:unit, _} -> {:error, :unit}
      {:name, _} -> {:error, :name}
      err -> {:error, err}
    end
  end

  def balance(discord_user_id) do
    from asset in Money.Asset,
      join: info in Money.Info,
      on: asset.money_id == info.id,
      join: discord_users in Money.DiscordUser,
      on: discord_users.discord_id == ^discord_user_id and asset.user_id == discord_users.user_id,
      select: {asset.amount, asset.status, info.name, info.unit, info.guild_id, info.status},
      order_by: info.unit
  end
end

defmodule VirtualCrypto.Money do
  alias VirtualCrypto.Repo
  alias Ecto.Multi

  @spec pay(
          sender: non_neg_integer(),
          receiver: non_neg_integer(),
          amount: non_neg_integer(),
          unit: String.t()
        ) ::
          {:ok}
          | {:error, :not_found_money}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def pay(kw) do
    case Multi.new()
         |> Multi.run(:pay, fn _, _ ->
           VirtualCrypto.Money.InternalAction.pay(
             Keyword.fetch!(kw, :sender),
             Keyword.fetch!(kw, :receiver),
             Keyword.fetch!(kw, :amount),
             Keyword.fetch!(kw, :unit)
           )
         end)
         |> Repo.transaction() do
      {:ok, _} -> {:ok}
      {:error, :pay, :not_found_money, _} -> {:error, :not_found_money}
      {:error, :pay, :not_found_sender_asset, _} -> {:error, :not_found_sender_asset}
      {:error, :pay, :not_enough_amount, _} -> {:error, :not_enough_amount}
    end
  end

  @spec give(receiver: non_neg_integer(), amount: non_neg_integer(), guild: non_neg_integer()) ::
          {:ok, Ecto.Schema.t()}
          | {:error, :not_found_money}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def give(kw) do
    guild = Keyword.fetch!(kw, :guild)

    case Multi.new()
         |> Multi.run(:give, fn _, _ ->
           VirtualCrypto.Money.InternalAction.give(
             Keyword.fetch!(kw, :receiver),
             Keyword.fetch!(kw, :amount),
             guild
           )
         end)
         |> Multi.run(:info, fn _, _ ->
           {:ok, VirtualCrypto.Money.InternalAction.get_money_by_guild_id(guild)}
         end)
         |> Repo.transaction() do
      {:ok, %{info: info}} -> {:ok, info}
      {:error, :give, :not_found_money, _} -> {:error, :not_found_money}
      {:error, :give, :not_found_sender_asset, _} -> {:error, :not_found_sender_asset}
      {:error, :give, :not_enough_amount, _} -> {:error, :not_enough_amount}
    end
  end

  defp _create(guild, name, unit, creator, creator_amount, pool_amount, retry) when retry > 0 do
    case Multi.new()
         |> Multi.run(:create, fn _, _ ->
           VirtualCrypto.Money.InternalAction.create(
             guild,
             name,
             unit,
             creator,
             creator_amount,
             pool_amount
           )
         end)
         |> Repo.transaction() do
      {:ok, _} ->
        {:ok}

      {:error, :create, :guild, _} ->
        {:error, :guild}

      {:error, :create, :unit, _} ->
        {:error, :unit}

      {:error, _, _, _} ->
        _create(guild, name, unit, creator, creator_amount, pool_amount, retry - 1)
    end
  end

  defp _create(_, _, _, _, _, _, _) do
    {:error, :retry_limit}
  end

  @spec create(
          guild: non_neg_integer(),
          name: String.t(),
          unit: String.t(),
          pool_amount: non_neg_integer(),
          retry_count: pos_integer(),
          creator: non_neg_integer(),
          creator_amount: pos_integer()
        ) ::
          {:ok} | {:error, :guild} | {:error, :unit} | {:error, :name} | {:error, :retry_limit}
  def create(kw) do
    _create(
      Keyword.fetch!(kw, :guild),
      Keyword.fetch!(kw, :name),
      Keyword.fetch!(kw, :unit),
      Keyword.fetch!(kw, :creator),
      Keyword.fetch!(kw, :creator_amount),
      Keyword.get(kw, :pool_amount, 0),
      Keyword.get(kw, :retry_count, 5)
    )
  end

  @spec balance(user: non_neg_integer()) :: [
          %{
            amount: non_neg_integer(),
            asset_status: non_neg_integer(),
            name: String.t(),
            unit: String.t(),
            guild: non_neg_integer(),
            money_status: non_neg_integer()
          }
        ]
  def balance(kw) do
    Repo.all(VirtualCrypto.Money.InternalAction.balance(Keyword.fetch!(kw, :user)))
    |> Enum.map(fn {asset_amount, asset_status, info_name, info_unit, info_guild_id, info_status} ->
      %{
        amount: asset_amount,
        asset_status: asset_status,
        name: info_name,
        unit: info_unit,
        guild: info_guild_id,
        money_status: info_status
      }
    end)
  end

  @spec info(name: String.t(), unit: String.t(), guild: non_neg_integer()) ::
          Ecto.Schema.t() | nil
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
