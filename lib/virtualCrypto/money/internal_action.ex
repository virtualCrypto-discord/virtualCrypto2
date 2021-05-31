defmodule VirtualCrypto.Money.InternalAction do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  alias VirtualCrypto.User.User
  import VirtualCrypto.User
  import Ecto.Query

  defguard is_non_neg_integer(v) when is_integer(v) and v >= 0
  defguard is_positive_integer(v) when is_integer(v) and v > 0

  # FIXME: order of parameters
  def pay(sender_id, receiver_discord_id, amount, currency_unit)
      when is_positive_integer(amount) do
    # Get currency info by unit.
    with currency <- get_currency_by_unit(currency_unit),
         # Is currency exits?
         {:currency, true} <- {:currency, currency != nil},
         # Get sender id.
         # Get sender asset by sender id and currency id.
         sender_asset <- get_asset_with_lock(sender_id, currency.id),
         # Is sender asset exists?
         {:sender_asset, true} <- {:sender_asset, sender_asset != nil},
         # Has sender enough amount?
         {:sender_asset_amount, true} <- {:sender_asset_amount, sender_asset.amount >= amount},
         # Insert receiver user if not exists.
         {:ok, %User{id: receiver_id}} <- insert_user_if_not_exists(receiver_discord_id),
         # Upsert receiver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, currency.id, amount),
         # Update sender amount.
         {:ok, _} <- update_asset_amount(sender_asset.id, -amount),
         {:ok, _} <-
           Repo.insert(%VirtualCrypto.Money.PaymentHistory{
             amount: amount,
             currency_id: currency.id,
             receiver_id: receiver_id,
             sender_id: sender_id,
             time: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
           }) do
      {:ok, nil}
    else
      {:currency, false} -> {:error, :not_found_currency}
      {:sender_asset, false} -> {:error, :not_found_sender_asset}
      {:sender_asset_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end

  def pay(_sender_id, _receiver_discord_id, _amount, _currency_unit) do
    {:error, :invalid_amount}
  end

  def bulk_pay(sender_id, currency_unit_receiver_id_and_amount) do
    time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    with {:check_amount, true} <-
           {:check_amount,
            currency_unit_receiver_id_and_amount |> Enum.all?(fn {_, _, amount} -> amount > 0 end)},
         currency_unit_receiver_id_and_amount_grouped <-
           currency_unit_receiver_id_and_amount |> Enum.group_by(fn {unit, _, _} -> unit end),
         units <- Map.keys(currency_unit_receiver_id_and_amount_grouped),
         q <-
           from(assets in Money.Asset,
             join: currencies in Money.Currency,
             on: currencies.id == assets.currency_id,
             where: assets.user_id == ^sender_id and currencies.unit in ^units,
             select: {assets.id, currencies.id, currencies.unit, assets.amount},
             lock: fragment("FOR UPDATE OF ?", assets)
           ),
         aid_sender_currency_id_unit_amount <- Repo.all(q),
         sender_currency_id_amount_pair <-
           aid_sender_currency_id_unit_amount
           |> Enum.map(fn {_aid, currency_id, _unit, amount} -> {currency_id, amount} end)
           |> Map.new(),
         sender_unit_currency_id_pair <-
           aid_sender_currency_id_unit_amount
           |> Enum.map(fn {_aid, currency_id, unit, _amount} -> {unit, currency_id} end)
           |> Map.new(),
         sender_currency_id_aid_pair <-
           aid_sender_currency_id_unit_amount
           |> Enum.map(fn {aid, currency_id, _unit, _amount} -> {currency_id, aid} end)
           |> Map.new(),
         sent_unit_amount_pair <-
           currency_unit_receiver_id_and_amount_grouped
           |> Enum.map(fn {unit, currency_unit_receiver_id_and_amount_grouped_entry} ->
             {unit,
              currency_unit_receiver_id_and_amount_grouped_entry
              |> Enum.map(fn {_unit, _receiver, amount} -> amount end)
              |> Enum.sum()}
           end),
         {:sender_asset_amount, true} <-
           {:sender_asset_amount,
            sent_unit_amount_pair
            |> Enum.all?(fn {unit, sent_amount} ->
              case Map.fetch(sender_unit_currency_id_pair, unit) do
                :error ->
                  false

                {:ok, currency_id} ->
                  Map.get(sender_currency_id_amount_pair, currency_id, 0) >= sent_amount
              end
            end)},
         {:ok, _} <-
           upsert_asset_amounts(
             currency_unit_receiver_id_and_amount
             |> Enum.map(fn {unit, receiver_id, amount} ->
               {sender_unit_currency_id_pair[unit], receiver_id, amount}
             end),
             time
           ),
         {_, _} <-
           update_asset_amounts(
             sent_unit_amount_pair
             |> Enum.map(fn {unit, sent_amount} ->
               {sender_currency_id_aid_pair[sender_unit_currency_id_pair[unit]], -sent_amount}
             end),
             time
           ),
         {_, _} <-
           Repo.insert_all(
             VirtualCrypto.Money.PaymentHistory,
             currency_unit_receiver_id_and_amount
             |> Enum.map(fn {unit, receiver_id, amount} ->
               %{
                 amount: amount,
                 currency_id: sender_unit_currency_id_pair[unit],
                 receiver_id: receiver_id,
                 sender_id: sender_id,
                 time: time,
                 inserted_at: time,
                 updated_at: time
               }
             end)
           ) do
      {:ok, nil}
    else
      {:check_amount, _} -> {:error, :invalid_amount}
      {:sender_asset_amount, _} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end

  def get_currency_by_unit(currency_unit) do
    Money.Currency
    |> where([m], m.unit == ^currency_unit)
    |> Repo.one()
  end

  def get_currency_by_name(name) do
    Repo.get_by(Money.Currency, name: name)
  end

  def get_asset_with_lock(user_id, currency_id) do
    Money.Asset
    |> where([a], a.user_id == ^user_id and a.currency_id == ^currency_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  def upsert_asset_amount(user_id, currency_id, amount) do
    Repo.insert(
      %Money.Asset{
        user_id: user_id,
        currency_id: currency_id,
        amount: amount
      },
      on_conflict: [inc: [amount: amount]],
      conflict_target: [:user_id, :currency_id]
    )
  end

  def upsert_asset_amounts(assets, now) do
    Repo.insert_all(
      VirtualCrypto.Money.Asset,
      assets
      |> Enum.map(fn {currency_id, user_id, amount} ->
        [
          amount: amount,
          user_id: user_id,
          currency_id: currency_id,
          inserted_at: now,
          updated_at: now
        ]
      end),
      on_conflict:
        from(assets in VirtualCrypto.Money.Asset,
          update: [
            inc: [amount: fragment("EXCLUDED.amount")]
          ]
        ),
      conflict_target: [:currency_id, :user_id]
    )

    {:ok, nil}
  end

  def update_asset_amount(asset_id, amount) do
    {_, nil} =
      Money.Asset
      |> where([a], a.id == ^asset_id)
      |> update(inc: [amount: ^amount])
      |> Repo.update_all([])

    {:ok, nil}
  end

  def update_asset_amounts([], _time) do
    {:ok, nil}
  end

  def update_asset_amounts([{asset_id, amount}], _time) do
    update_asset_amount(asset_id, amount)

    {:ok, nil}
  end

  def update_asset_amounts(list, time) do
    q = 2..length(list) |> Enum.map(&"($#{&1 * 2},$#{&1 * 2 + 1})") |> Enum.join(",")

    Ecto.Adapters.SQL.query!(
      Repo,
      "UPDATE assets SET amount = assets.amount + tmp.amount, updated_at = $1 FROM (VALUES ($2::bigint,$3::integer),#{
        q
      }) as tmp (id, amount) WHERE assets.id=tmp.id;",
      [time | list |> Enum.flat_map(fn {a, b} -> [a, b] end)]
    )

    {:ok, nil}
  end

  def get_currency_by_guild_id_with_lock(guild_id) do
    Money.Currency
    |> where([m], m.guild_id == ^guild_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  def get_currency_by_guild_id(guild_id) do
    Money.Currency
    |> where([m], m.guild_id == ^guild_id)
    |> Repo.one()
  end

  def get_currency_by_id(id) do
    Money.Currency
    |> where([m], m.id == ^id)
    |> Repo.one()
  end

  def update_pool_amount(currency_id, amount) do
    {1, nil} =
      Money.Currency
      |> where([a], a.id == ^currency_id)
      |> update(inc: [pool_amount: ^amount])
      |> Repo.update_all([])

    {:ok, nil}
  end

  def info(:guild, guild_id) do
    from(asset in Money.Asset,
      join: currency in Money.Currency,
      on: asset.currency_id == currency.id,
      where: currency.guild_id == ^guild_id,
      group_by: currency.id,
      select:
        {sum(asset.amount), currency.name, currency.unit, currency.guild_id, currency.pool_amount}
    )
  end

  def info(:name, name) do
    from(asset in Money.Asset,
      join: currency in Money.Currency,
      on: asset.currency_id == currency.id,
      where: currency.name == ^name,
      group_by: currency.id,
      select:
        {sum(asset.amount), currency.name, currency.unit, currency.guild_id, currency.pool_amount}
    )
  end

  def info(:unit, unit) do
    from(asset in Money.Asset,
      join: currency in Money.Currency,
      on: asset.currency_id == currency.id,
      where: currency.unit == ^unit,
      group_by: currency.id,
      select:
        {sum(asset.amount), currency.name, currency.unit, currency.guild_id, currency.pool_amount}
    )
  end

  def info(:id, id) do
    from(asset in Money.Asset,
      join: currency in Money.Currency,
      on: asset.currency_id == currency.id,
      where: currency.id == ^id,
      group_by: currency.id,
      select:
        {sum(asset.amount), currency.name, currency.unit, currency.guild_id, currency.pool_amount}
    )
  end

  @reset_pool_amount """
  WITH
    supplied_amounts AS (
      SELECT
        currency_id,
        SUM(amount) as supplied_amount
      FROM assets GROUP BY currency_id
    ),
    schedules AS (
      SELECT
      currency_id,
        (
          CASE
            WHEN (supplied_amounts.supplied_amount+199)/200<5 THEN 5
            ELSE (supplied_amounts.supplied_amount+199)/200
          END
        ) AS increasing_pool_amount,
        (
          CASE
            WHEN (supplied_amounts.supplied_amount*7+199)/200<35 THEN 35
            ELSE (supplied_amounts.supplied_amount*7+199)/200
          END
        ) AS pool_amount_limit
      FROM supplied_amounts
    )
  UPDATE currencies
  SET pool_amount =
    CASE
      WHEN schedules.increasing_pool_amount+pool_amount>schedules.pool_amount_limit THEN schedules.pool_amount_limit
      ELSE schedules.increasing_pool_amount+pool_amount
    END
  FROM schedules
  WHERE schedules.currency_id = currencies.id
  ;
  """
  def reset_pool_amount() do
    Ecto.Adapters.SQL.query!(Repo, @reset_pool_amount)
  end

  def get_claim_by_id(id) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        where: claim.id == ^id,
        select: %{claim: claim, currency: currency, claimant: claimant, payer: payer}
      )

    query |> Repo.one()
  end

  def create_claim(claimant_user_id, payer_user_id, unit, amount)
      when is_positive_integer(amount) and amount <= 9_223_372_036_854_775_807 do
    case Money.Currency |> where([i], i.unit == ^unit) |> Repo.one() do
      nil ->
        {:error, :not_found_currency}

      currency ->
        {:ok, claim} =
          %Money.Claim{
            amount: amount,
            status: "pending",
            claimant_user_id: claimant_user_id,
            payer_user_id: payer_user_id,
            currency_id: currency.id
          }
          |> Repo.insert()

        {:ok, get_claim_by_id(claim.id)}
    end
  end

  def create_claim(_claimant_user_id, _payer_user_id, _unit, _amount) do
    {:error, :invalid_amount}
  end

  def create(guild, name, unit, creator_discord_id, creator_amount, pool_amount)
      when is_non_neg_integer(pool_amount) and is_non_neg_integer(creator_amount) and
             creator_amount <= 4_294_967_295 do
    # Check duplicate guild.
    with {:guild, nil} <- {:guild, get_currency_by_guild_id(guild)},
         # Check duplicate unit.
         {:unit, nil} <- {:unit, get_currency_by_unit(unit)},
         {:name, nil} <- {:name, get_currency_by_name(name)},
         # Create creator user
         {:ok, %User{id: creator_id}} <- insert_user_if_not_exists(creator_discord_id) do
      # Insert new currency.
      # This operation may occur serialization(If transaction isolation level serializable.) or constraint(If other transaction isolation level) error.
      {:ok, currency} =
        Repo.insert(
          %Money.Currency{
            guild_id: guild,
            pool_amount: pool_amount,
            name: name,
            unit: unit
          },
          returning: true
        )

      # Insert creator asset.
      # Always success.
      creator_asset =
        Repo.insert!(%Money.Asset{
          amount: creator_amount,
          user_id: creator_id,
          currency_id: currency.id
        })

      {:ok, creator_asset}
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

  def give(receiver_discord_id, :all, guild_id) do
    # Get currency info by guild.
    with currency <- get_currency_by_guild_id_with_lock(guild_id),
         # Is currency exits?
         {:currency, true} <- {:currency, currency != nil},
         {:pool_amount, amount} when amount > 0 <- {:pool_amount, currency.pool_amount},
         # Insert receiver user if not exists.
         {:ok, %User{id: receiver_id}} <- insert_user_if_not_exists(receiver_discord_id),
         # Update receiver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, currency.id, amount),
         # Update pool amount.
         {:ok, _} <- update_pool_amount(currency.id, -amount),
         {:ok, _} <-
           Repo.insert(%VirtualCrypto.Money.GivenHistory{
             amount: amount,
             currency_id: currency.id,
             time: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
             receiver_id: receiver_id
           }) do
      {:ok, %{amount: amount, currency: %{currency | pool_amount: currency.pool_amount - amount}}}
    else
      {:currency, false} -> {:error, :not_found_currency}
      {:pool_amount, _} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end

  def give(receiver_discord_id, amount, guild_id)
      when is_positive_integer(amount) do
    # Get currency info by guild.
    with currency <- get_currency_by_guild_id_with_lock(guild_id),
         # Is currency exits?
         {:currency, true} <- {:currency, currency != nil},
         # Check pool amount enough.
         {:pool_amount, true} <- {:pool_amount, currency.pool_amount >= amount},
         # Insert receiver user if not exists.
         {:ok, %User{id: receiver_id}} <- insert_user_if_not_exists(receiver_discord_id),
         # Update receiver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, currency.id, amount),
         # Update pool amount.
         {:ok, _} <- update_pool_amount(currency.id, -amount),
         {:ok, _} <-
           Repo.insert(%VirtualCrypto.Money.GivenHistory{
             amount: amount,
             currency_id: currency.id,
             time: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
             receiver_id: receiver_id
           }) do
      {:ok, %{amount: amount, currency: currency}}
    else
      {:currency, false} -> {:error, :not_found_currency}
      {:pool_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end

  def give(_receiver_discord_id, _amount, _guild_id) do
    {:error, :invalid_amount}
  end

  defp claims_base_query do
    from(claim in Money.Claim,
      join: currency in Money.Currency,
      join: claimant in VirtualCrypto.User.User,
      join: payer in VirtualCrypto.User.User,
      on:
        claim.payer_user_id == payer.id and claim.currency_id == currency.id and
          claim.claimant_user_id == claimant.id,
      select: %{claim: claim, currency: currency, claimant: claimant, payer: payer}
    )
  end

  def get_sent_claim(id, user_id) do
    query =
      claims_base_query()
      |> where(
        [claim, currency, claimant, payer],
        claim.id == ^id and claim.claimant_user_id == ^user_id
      )

    query |> Repo.one()
  end

  def get_sent_claim(id, user_id, status) do
    query =
      claims_base_query()
      |> where(
        [claim, currency, claimant, payer],
        claim.id == ^id and claim.claimant_user_id == ^user_id and ^status == claim.status
      )

    query |> Repo.one()
  end

  def get_received_claim(id, user_id) do
    query =
      claims_base_query()
      |> where(
        [claim, currency, claimant, payer],
        claim.id == ^id and claim.payer_user_id == ^user_id
      )

    query |> Repo.one()
  end

  def get_received_claim(id, user_id, status) do
    query =
      claims_base_query()
      |> where(
        [claim, currency, claimant, payer],
        claim.id == ^id and claim.payer_user_id == ^user_id and ^status == claim.status
      )

    query |> Repo.one()
  end

  def get_sent_claims(user_id) do
    query =
      claims_base_query()
      |> where([claim, info, claimant, payer], claim.claimant_user_id == ^user_id)

    query |> Repo.all()
  end

  def get_sent_claims(user_id, status) do
    query =
      claims_base_query()
      |> where(
        [claim, currency, claimant, payer],
        claim.claimant_user_id == ^user_id and claim.status == ^status
      )

    query |> Repo.all()
  end

  def get_received_claims(user_id) do
    query =
      claims_base_query()
      |> where(
        [claim, currency, claimant, payer],
        claim.payer_user_id == ^user_id
      )

    query |> Repo.all()
  end

  def get_received_claims(user_id, status) do
    query =
      claims_base_query()
      |> where(
        [claim, currency, claimant, payer],
        claim.payer_user_id == ^user_id and claim.status == ^status
      )

    query |> Repo.all()
  end

  defp sr_filter(q, :all, user_id) do
    q
    |> where(
      [claim, currency, claimant, payer],
      claim.payer_user_id == ^user_id or claim.claimant_user_id == ^user_id
    )
  end

  defp sr_filter(q, :received, user_id) do
    q |> where([claim, currency, claimant, payer], claim.payer_user_id == ^user_id)
  end

  defp sr_filter(q, :claimed, user_id) do
    q |> where([claim, currency, claimant, payer], claim.claimant_user_id == ^user_id)
  end

  defmacrop get_claims_m_q(
              q,
              operator_id,
              statuses,
              sr_filter,
              related_user_id,
              order_by,
              cond_expr,
              limit \\ nil
            ) do
    q =
      quote do
        operator_id = unquote(operator_id)
        statuses = unquote(statuses)
        related_user_id = unquote(related_user_id)

        q =
          unquote(q)
          |> where(
            [claim, currency, claimant, payer],
            claim.status in ^statuses and unquote(cond_expr)
          )
          |> sr_filter(unquote(sr_filter), operator_id)

        q =
          case related_user_id do
            nil -> q
            related_user_id -> q |> sr_filter(:all, related_user_id)
          end

        q |> order_by([claim, info, claimant, payer], unquote(order_by))
      end

    case limit do
      nil ->
        q

      _ ->
        quote do
          limit = unquote(limit)

          case limit do
            {limit, offset} ->
              unquote(q)
              |> limit(^limit)
              |> offset(^offset)

            limit ->
              unquote(q)
              |> limit(^limit)
          end
        end
    end
  end

  defmacrop get_claims_m(
              operator_id,
              statuses,
              sr_filter,
              related_user_id,
              order_by,
              cond_expr,
              limit \\ nil
            ) do
    quote do
      get_claims_m_q(
        claims_base_query(),
        unquote(operator_id),
        unquote(statuses),
        unquote(sr_filter),
        unquote(related_user_id),
        unquote(order_by),
        unquote(cond_expr),
        unquote(limit)
      )
      |> Repo.all()
    end
  end

  def get_claims(
        operator_id,
        statuses \\ ["pending", "approved", "canceled", "denied"]
      ) do
    get_claims(operator_id, statuses, :all, nil, :desc_claim_id)
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id
      ) do
    get_claims_m(operator_id, statuses, sr_filter, related_user_id, [desc: claim.id], ^true)
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        :desc_claim_id,
        limit
      ) do
    get_claims(
      operator_id,
      statuses,
      sr_filter,
      nil,
      :desc_claim_id,
      %{cursor: :first},
      limit
    )
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{cursor: :first},
        limit
      ) do
    get_claims_m(
      operator_id,
      statuses,
      sr_filter,
      related_user_id,
      [desc: claim.id],
      ^true,
      limit
    )
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{page: :last},
        limit
      ) do
    q =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        select: count(claim.id)
      )

    [cnt] =
      get_claims_m_q(q, operator_id, statuses, sr_filter, related_user_id, [], ^true)
      |> Repo.all()

    page = div(cnt + limit - 1, limit)

    limit =
      case rem(cnt, limit) do
        0 -> limit
        x -> x
      end

    result =
      get_claims_m(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        [asc: claim.id],
        ^true,
        limit
      )

    {first, prev} = if cnt > limit, do: {1, page - 1}, else: {nil, nil}

    %{
      claims: result |> Enum.reverse(),
      next: nil,
      prev: prev,
      last: nil,
      first: first,
      page: page
    }
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{page: n},
        limit
      ) do
    result =
      get_claims_m(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        [desc: claim.id],
        ^true,
        {limit + 1, limit * (n - 1)}
      )

    prev? = n != 1
    next? = Enum.count(result) > limit
    {first, prev} = if prev?, do: {1, n - 1}, else: {nil, nil}
    {last, next} = if next?, do: {:last, n + 1}, else: {nil, nil}

    %{
      claims: result |> Enum.take(limit),
      next: next,
      prev: prev,
      last: last,
      first: first,
      page: n
    }
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{cursor: {:after, x}},
        limit
      ) do
    get_claims_m(
      operator_id,
      statuses,
      sr_filter,
      related_user_id,
      [desc: claim.id],
      claim.id < ^x,
      limit
    )
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{cursor: {:before, x}},
        limit
      ) do
    get_claims_m(
      operator_id,
      statuses,
      sr_filter,
      related_user_id,
      [asc: claim.id],
      claim.id > ^x,
      limit
    )
    |> Enum.reverse()
  end

  defp update_claim_status(id, new_status) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    result =
      Money.Claim
      |> where([c], c.id == ^id and c.status == "pending")
      |> update(set: [status: ^new_status, updated_at: ^now])
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
