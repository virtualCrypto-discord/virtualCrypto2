defmodule VirtualCrypto.Money.Query.Currency do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  import VirtualCrypto.Money.Query.Util
  import Ecto.Query

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

  def update_pool_amount(currency_id, amount) do
    {1, nil} =
      Money.Currency
      |> where([a], a.id == ^currency_id)
      |> update(inc: [pool_amount: ^amount])
      |> Repo.update_all([])

    {:ok, nil}
  end

  def create(guild, name, unit, creator, creator_amount, pool_amount)
      when is_non_neg_integer(pool_amount) and is_non_neg_integer(creator_amount) and
             creator_amount <= 4_294_967_295 do
    # Check duplicate guild.
    with {:guild, nil} <- {:guild, get_currency_by_guild_id(guild)},
         # Check duplicate unit.
         {:unit, nil} <- {:unit, get_currency_by_unit(unit)},
         # Check duplicate name.
         {:name, nil} <- {:name, get_currency_by_name(name)},
         # Create creator user
         creator_id <- UserResolvable.resolve_id(creator) do
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

  def get_currency_by_unit(currency_unit) do
    Money.Currency
    |> where([m], m.unit == ^currency_unit)
    |> Repo.one()
  end

  def get_currency_by_name(name) do
    Repo.get_by(Money.Currency, name: name)
  end

  def get_currency_by_guild_id(guild_id) do
    Money.Currency
    |> where([m], m.guild_id == ^guild_id)
    |> Repo.one()
  end

  def get_currency_by_guild_id_with_lock(guild_id) do
    Money.Currency
    |> where([m], m.guild_id == ^guild_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  def get_currency_by_id(id) do
    Money.Currency
    |> where([m], m.id == ^id)
    |> Repo.one()
  end

  def search_currencies_with_asset_by_unit(
        unit,
        guild_id,
        %DiscordUser{id: discord_user_id},
        limit
      ) do
    q =
      from(currencies in Money.Currency,
        left_join: assets in Money.Asset,
        on: assets.currency_id == currencies.id,
        left_join: users in VirtualCrypto.User.User,
        on: users.discord_id == ^discord_user_id and assets.user_id == users.id,
        where: ilike(currencies.unit, ^"#{escape_like_query(unit)}%"),
        select: %{
          amount:
            fragment(
              "CASE ? WHEN ? THEN ? ELSE 0 END",
              users.discord_id,
              ^discord_user_id,
              assets.amount
            ),
          currency: currencies
        },
        order_by: [
          {:desc, currencies.guild_id == ^guild_id},
          {:desc,
           fragment(
             "CASE ? WHEN ? THEN ? != 0 ELSE FALSE END",
             users.discord_id,
             ^discord_user_id,
             assets.amount
           )},
          {:asc, fragment("char_length(?)", currencies.unit)},
          fragment(
            "? DESC NULLS LAST",
            fragment(
              "CASE ? WHEN ? THEN ? ELSE NULL END",
              users.discord_id,
              ^discord_user_id,
              assets.updated_at
            )
          )
        ],
        limit: ^limit
      )

    Repo.all(q)
  end

  def search_currencies_with_asset_by_unit(unit, guild_id, user, limit) do
    user_id = UserResolvable.resolve_id(user)

    q =
      from(currencies in Money.Currency,
        left_join: assets in Money.Asset,
        on: assets.currency_id == currencies.id and assets.user_id == ^user_id,
        where: ilike(currencies.unit, ^"#{escape_like_query(unit)}%"),
        order_by: [
          {:desc, currencies.guild_id == ^guild_id},
          {:desc,
           fragment(
             "CASE ? WHEN ? THEN ? != 0 ELSE FALSE END",
             assets.id,
             ^user_id,
             assets.amount
           )},
          {:asc, fragment("char_length(?)", currencies.unit)},
          fragment(
            "? DESC NULLS LAST",
            fragment(
              "CASE ? WHEN ? THEN ? ELSE NULL END",
              assets.id,
              ^user_id,
              assets.updated_at
            )
          )
        ],
        select: %{
          amount:
            fragment(
              "CASE ? WHEN ? THEN ? ELSE 0 END",
              assets.id,
              ^user_id,
              assets.amount
            ),
          currency: currencies
        },
        limit: ^limit
      )

    Repo.all(q)
  end

  def search_currencies_with_asset_by_name(
        name,
        guild_id,
        %DiscordUser{id: discord_user_id},
        limit
      ) do
    q =
      from(currencies in Money.Currency,
        left_join: assets in Money.Asset,
        on: assets.currency_id == currencies.id,
        left_join: users in VirtualCrypto.User.User,
        on: users.discord_id == ^discord_user_id and assets.user_id == users.id,
        where: ilike(currencies.name, ^"#{escape_like_query(name)}%"),
        select: %{
          amount:
            fragment(
              "CASE ? WHEN ? THEN ? ELSE 0 END",
              users.discord_id,
              ^discord_user_id,
              assets.amount
            ),
          currency: currencies
        },
        order_by: [
          desc: currencies.guild_id == ^guild_id,
          desc:
            fragment(
              "CASE ? WHEN ? THEN ? != 0 ELSE FALSE END",
              users.discord_id,
              ^discord_user_id,
              assets.amount
            ),
          asc: fragment("char_length(?)", currencies.name),
          asc: currencies.id
        ],
        limit: ^limit
      )

    Repo.all(q)
  end

  def search_currencies_with_asset_by_name(name, guild_id, user, limit) do
    user_id = UserResolvable.resolve_id(user)

    q =
      from(currencies in Money.Currency,
        left_join: assets in Money.Asset,
        on: assets.currency_id == currencies.id and assets.user_id == ^user_id,
        where: ilike(currencies.name, ^"#{escape_like_query(name)}%"),
        order_by: [
          desc: currencies.guild_id == ^guild_id,
          desc:
            fragment(
              "CASE ? WHEN ? THEN ? != 0 ELSE FALSE END",
              assets.id,
              ^user_id,
              assets.amount
            ),
          asc: fragment("char_length(?)", currencies.name),
          asc: currencies.id
        ],
        select: %{
          amount:
            fragment(
              "CASE ? WHEN ? THEN ? ELSE 0 END",
              assets.id,
              ^user_id,
              assets.amount
            ),
          currency: currencies
        },
        limit: ^limit
      )

    Repo.all(q)
  end

  def search_currencies_with_asset_by_guild_and_user(
        guild_id,
        %DiscordUser{id: discord_user_id},
        limit
      ) do
    q =
      from(currencies in Money.Currency,
        left_join: assets in Money.Asset,
        on: assets.currency_id == currencies.id,
        left_join: users in VirtualCrypto.User.User,
        on: users.discord_id == ^discord_user_id and assets.user_id == users.id,
        select: %{
          amount:
            fragment(
              "CASE ? WHEN ? THEN ? ELSE 0 END",
              users.discord_id,
              ^discord_user_id,
              assets.amount
            ),
          currency: currencies
        },
        order_by: [
          desc: currencies.guild_id == ^guild_id,
          desc:
            fragment(
              "CASE ? WHEN ? THEN ? != 0 ELSE FALSE END",
              users.discord_id,
              ^discord_user_id,
              assets.amount
            ),
          asc: currencies.id
        ],
        limit: ^limit
      )

    Repo.all(q)
  end

  def search_currencies_with_asset_by_guild_and_user(
        guild_id,
        user,
        limit
      ) do
    user_id = UserResolvable.resolve_id(user)

    q =
      from(currencies in Money.Currency,
        left_join: assets in Money.Asset,
        on: assets.currency_id == currencies.id,
        where: assets.user_id == ^user_id or currencies.guild_id == ^guild_id,
        select: %{
          amount:
            fragment(
              "CASE ? WHEN ? THEN ? ELSE 0 END",
              assets.id,
              ^user_id,
              assets.amount
            ),
          currency: currencies
        },
        order_by: [
          desc: currencies.guild_id == ^guild_id,
          desc:
            fragment(
              "CASE ? WHEN ? THEN ? != 0 ELSE FALSE END",
              assets.id,
              ^user_id,
              assets.amount
            ),
          asc: currencies.id
        ],
        limit: ^limit
      )

    Repo.all(q)
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
end
