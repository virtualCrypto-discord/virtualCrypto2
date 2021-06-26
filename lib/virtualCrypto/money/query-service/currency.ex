defmodule VirtualCrypto.Money.Query.Currency do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
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

  def get_currency_by_id(id) do
    Money.Currency
    |> where([m], m.id == ^id)
    |> Repo.one()
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
