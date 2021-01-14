defmodule VirtualCrypto.Money.InternalAction do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  alias VirtualCrypto.User.User
  import Ecto.Query
  import VirtualCrypto.User
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
    |> update(inc: [amount: ^amount])
    |> Repo.update_all([])
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

  def get_money_by_id(id) do
    Money.Info
    |> where([m], m.id == ^id)
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
         # Get sender id.
         {:ok, %User{id: sender_id}} <- insert_user_if_not_exits(sender_discord_id),
         # Get sender asset by sender id and money id.
         sender_asset <- get_asset_with_lock(sender_id, money.id),
         # Is sender asset exsits?
         {:sender_asset, true} <- {:sender_asset, sender_asset != nil},
         # Has sender enough amount?
         {:sender_asset_amount, true} <- {:sender_asset_amount, sender_asset.amount >= amount},
         # Insert reciver user if not exists.
         {:ok, %User{id: receiver_id}} <- insert_user_if_not_exits(receiver_discord_id),
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

  def give(receiver_discord_id, amount, guild_id)
      when is_positive_integer(amount) do
    # Get money info by guild.
    with money <- get_money_by_guild_id_with_lock(guild_id),
         # Is money exits?
         {:money, true} <- {:money, money != nil},
         # Check pool amount enough.
         {:pool_amount, true} <- {:pool_amount, money.pool_amount >= amount},
         # Insert reciver user if not exists.
         {:ok, %User{id: receiver_id}} <- insert_user_if_not_exits(receiver_discord_id),
         # Update reciver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, money.id, amount) do
      # Update pool amount.
      {:ok, update_pool_amount(money.id, -amount)}
    else
      {:money, false} -> {:error, :not_found_money}
      {:pool_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end

  def create(guild, name, unit, creator_discord_id, creator_amount, pool_amount)
      when is_non_neg_integer(pool_amount) and is_non_neg_integer(creator_amount) do
    # Check duplicate guild.
    with {:guild, nil} <- {:guild, get_money_by_guild_id(guild)},
         # Check duplicate unit.
         {:unit, nil} <- {:unit, get_money_by_unit(unit)},
         {:name, nil} <- {:name, get_money_by_name(name)},
         # Create creator user
         {:ok, %User{id: creator_id}} <- insert_user_if_not_exits(creator_discord_id) do
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

  def balance(discord_user_id) do
    from asset in Money.Asset,
      join: info in Money.Info,
      on: asset.money_id == info.id,
      join: users in User,
      on: users.discord_id == ^discord_user_id and users.id == asset.user_id,
      select: {asset.amount, asset.status, info.name, info.unit, info.guild_id, info.status},
      order_by: info.unit
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
  SET pool_amount = (temp.distribution_volume+199)/200
  FROM (SELECT money_id,SUM(amount) AS distribution_volume FROM assets GROUP BY money_id) AS temp
  WHERE temp.money_id = info.id
  ;
  """
  def reset_pool_amount() do
    Ecto.Adapters.SQL.query!(Repo, @reset_pool_amount)
  end

  def get_claim_by_id(id) do
    Money.Claim
    |> where([c], c.id == ^id)
    |> Repo.one()
  end

  def get_sent_claim(id, discord_user_id) do
    {:ok, user} = VirtualCrypto.User.insert_user_if_not_exits(discord_user_id)
    Money.Claim
    |> where([c], c.id == ^id and c.claimant_user_id == ^user.id)
    |> Repo.one()
  end

  def get_received_claim(id, discord_user_id) do
    {:ok, user} = VirtualCrypto.User.insert_user_if_not_exits(discord_user_id)
    Money.Claim
    |> where([c], c.id == ^id and c.payer_user_id == ^user.id)
    |> Repo.one()
  end

  def get_claims_by_discord_user_id(discord_user_id) do
    {:ok, user} = VirtualCrypto.User.insert_user_if_not_exits(discord_user_id)
    sent_claims = Money.Claim |> where([c], c.claimant_user_id == ^user.id) |> Repo.all()
    received_claims = Money.Claim |> where([c], c.payer_user_id == ^user.id) |> Repo.all()
    {sent_claims, received_claims}
  end

  def create_claim(claimant_user, payer_user, unit, amount, message) do
    r = Repo.transaction(fn -> info = Money.Info |> where([i], i.unit == ^ unit) |> Repo.one()
                               %Money.Claim{
                                 amount: amount,
                                 message: message,
                                 status: "pending",
                                 claimant_user_id: claimant_user.id,
                                 payer_user_id: payer_user.id,
                                 money_info_id: info.id
                               }
                               |> Repo.insert() end)
    case r do
      {:ok, v} -> v
      v -> v
    end
  end

  def approve_claim(id, discord_user_id) do
    {:ok, user} = VirtualCrypto.User.insert_user_if_not_exits(discord_user_id)
    r = Repo.transaction(fn ->
      {result, _} =
        Money.Claim
        |> where([c], c.id == ^id and c.payer_user_id == ^user.id and c.status == "pending")
        |> update(set: [status: "approved"])
        |> Repo.update_all([])
      case result do
        0 -> {:error, :not_found}
        _ -> {:ok, result}
      end
    end)
    case r do
      {:ok, v} -> v
      v -> v
    end
  end

  def deny_claim(id, discord_user_id) do
    {:ok, user} = VirtualCrypto.User.insert_user_if_not_exits(discord_user_id)
    r = Repo.transaction(fn ->
      {result, _} =
        Money.Claim
        |> where([c], c.id == ^id and c.payer_user_id == ^user.id and c.status == "pending")
        |> update(set: [status: "denied"])
        |> Repo.update_all([])
      case result do
        0 -> {:error, :not_found}
        _ -> {:ok, result}
      end
    end)
    case r do
      {:ok, v} -> v
      v -> v
    end
  end

  def cancel_claim(id, discord_user_id) do
    {:ok, user} = VirtualCrypto.User.insert_user_if_not_exits(discord_user_id)
    r = Repo.transaction(fn ->
      {result, _} =
        Money.Claim
        |> where([c], c.id == ^id and c.claimant_user_id == ^user.id and c.status == "pending")
        |> update(set: [status: "canceled"])
        |> Repo.update_all([])
      case result do
        0 -> {:error, :not_found}
        _ -> {:ok, result}
      end
    end)
    case r do
      {:ok, v} -> v
      v -> v
    end
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
          retry_count: pos_integer(),
          creator: non_neg_integer(),
          creator_amount: pos_integer()
        ) ::
          {:ok} | {:error, :guild} | {:error, :unit} | {:error, :name} | {:error, :retry_limit}
  def create(kw) do
    creator_amount = Keyword.fetch!(kw, :creator_amount)

    _create(
      Keyword.fetch!(kw, :guild),
      Keyword.fetch!(kw, :name),
      Keyword.fetch!(kw, :unit),
      Keyword.fetch!(kw, :creator),
      creator_amount,
      div(creator_amount + 199, 200),
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
          %{
            amount: non_neg_integer(),
            name: String.t(),
            unit: String.t(),
            guild: non_neg_integer(),
            money_status: non_neg_integer(),
            pool_amount: non_neg_integer()
          }
          | nil
  def info(kw) do
    raw =
      with {:name, nil} <- {:name, Keyword.get(kw, :name)},
           {:unit, nil} <- {:unit, Keyword.get(kw, :unit)},
           {:guild, nil} <- {:guild, Keyword.get(kw, :guild)} do
        raise "Invalid Argument. Must supply one or more arguments."
      else
        {atom, key} -> Repo.one(VirtualCrypto.Money.InternalAction.info(atom, key))
      end

    case raw do
      {amount, info_name, info_unit, info_guild_id, info_status, pool_amount} ->
        %{
          amount: amount,
          name: info_name,
          unit: info_unit,
          guild: info_guild_id,
          money_status: info_status,
          pool_amount: pool_amount
        }

      nil ->
        nil
    end
  end

  @spec reset_pool_amount() :: nil
  def reset_pool_amount() do
    VirtualCrypto.Money.InternalAction.reset_pool_amount()
    nil
  end

  @spec get_pending_claims(Integer.t()) :: {[VirtualCrypto.Money.Claim], [VirtualCrypto.Money.Claim]}
  def get_pending_claims(discord_user_id) do
    {sent, received} = VirtualCrypto.Money.InternalAction.get_claims_by_discord_user_id(discord_user_id)
    sent_ = sent |> Enum.filter(fn claim -> claim.status == "pending" end)
    received_ = received |> Enum.filter(fn claim -> claim.status == "pending" end)
    {sent_, received_}
  end

  @spec get_all_claims(Integer.t()) :: {[VirtualCrypto.Money.Claim], [VirtualCrypto.Money.Claim]}
  def get_all_claims(discord_user_id) do
    VirtualCrypto.Money.InternalAction.get_claims_by_discord_user_id(discord_user_id)
  end

  @spec approve_claim(Integer.t(), Integer.t()) ::
          {:ok}
          | {:error, :not_found}
          | {:error, :not_found_money}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def approve_claim(id, discord_user_id) do
    claim = VirtualCrypto.Money.InternalAction.get_received_claim(id, discord_user_id)
    with true <- claim != nil,
      true <- claim.status == "pending",
      user <- VirtualCrypto.User.get_user_by_id(claim.claimant_user_id),
      info <- VirtualCrypto.Money.InternalAction.get_money_by_id(claim.money_info_id),
      {:ok} <- pay(sender: discord_user_id, receiver: user.discord_id, amount: claim.amount, unit: info.unit),
      {:ok, _} <- VirtualCrypto.Money.InternalAction.approve_claim(id, discord_user_id)
    do
      {:ok}
    else
      false -> {:error, :not_found}
      nil -> {:error, :not_found}
      err -> err
    end
  end

  @spec cancel_claim(Integer.t(), Integer.t()) ::
          {:ok}
          | {:error, :not_found}
  def cancel_claim(id, discord_user_id) do
    claim = VirtualCrypto.Money.InternalAction.get_sent_claim(id, discord_user_id)
    with false <- claim == nil,
      true <- claim.status == "pending",
      {:ok, _} <- VirtualCrypto.Money.InternalAction.cancel_claim(id, discord_user_id)
    do
      {:ok}
    else
      false -> {:error, :not_found}
      nil -> {:error, :not_found}
      err -> err
    end
  end

  @spec deny_claim(Integer.t(), Integer.t()) ::
          {:ok}
          | {:error, :not_found}
  def deny_claim(id, discord_user_id) do
    claim = VirtualCrypto.Money.InternalAction.get_received_claim(id, discord_user_id)
    with false <- claim == nil,
      true <- claim.status == "pending",
      {:ok, _} <- VirtualCrypto.Money.InternalAction.deny_claim(id, discord_user_id)
    do
      {:ok}
    else
      false -> {:error, :not_found}
      nil -> {:error, :not_found}
      err -> err
    end
  end

  @spec create_claim(Integer.t(), Integer.t(), String.t(), Integer.t(), String.t()) :: VirtualCrypto.Money.Claim
  def create_claim(claimant_discord_user_id, payer_discord_user_id, unit, amount, message) do
    {:ok, claimant_user} = VirtualCrypto.User.insert_user_if_not_exits(claimant_discord_user_id)
    {:ok, payer_user} = VirtualCrypto.User.insert_user_if_not_exits(payer_discord_user_id)
    VirtualCrypto.Money.InternalAction.create_claim(claimant_user, payer_user, unit, amount, message)
  end
end
