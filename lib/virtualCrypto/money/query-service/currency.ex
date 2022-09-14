defmodule VirtualCrypto.Money.Query.Currency do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  import VirtualCrypto.Money.Query.Util
  import Ecto.Query

  def enact(name, unit) do
    # Check duplicate unit.
    with {:unit, nil} <- {:unit, get_currency_by_unit(unit)},
         # Check duplicate name.
         {:name, nil} <- {:name, get_currency_by_name(name)} do
      # Insert new currency.
      # This operation may occur serialization(If transaction isolation level serializable.) or constraint(If other transaction isolation level) error.
      {:ok, currency} =
        Repo.insert(
          %Money.Currency{
            name: name,
            unit: unit
          },
          returning: true
        )

      {:ok, currency}
    else
      {:unit, _} -> {:error, :unit}
      {:name, _} -> {:error, :name}
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

  def get_currency_by_id(id) do
    Money.Currency
    |> where([m], m.id == ^id)
    |> Repo.one()
  end

  def get_currency_by_id_with_lock(id) do
    Money.Currency
    |> where([m], m.id == ^id)
    |> lock("FOR UPDATE")
    |> Repo.one()
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
             "? != 0",
             assets.amount
           )},
          {:asc, fragment("char_length(?)", currencies.unit)},
          fragment(
            "? DESC NULLS LAST",
            assets.updated_at
          )
        ],
        select: %{
          amount: assets.amount |> coalesce(0),
          currency: currencies
        },
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
              "? != 0",
              assets.amount
            ),
          asc: fragment("char_length(?)", currencies.name),
          asc: currencies.id
        ],
        select: %{
          amount: assets.amount |> coalesce(0),
          currency: currencies
        },
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
        on: assets.currency_id == currencies.id and assets.user_id == ^user_id,
        where: assets.user_id == ^user_id or currencies.guild_id == ^guild_id,
        select: %{
          amount: assets.amount |> coalesce(0),
          currency: currencies
        },
        order_by: [
          desc: currencies.guild_id == ^guild_id,
          desc:
            fragment(
              "? != 0",
              assets.amount
            ),
          asc: currencies.id
        ],
        limit: ^limit
      )

    Repo.all(q)
  end

  def info(:name, name) do
    from(asset in Money.Asset,
      join: currency in Money.Currency,
      on: asset.currency_id == currency.id,
      where: currency.name == ^name,
      group_by: currency.id,
      select:
        {sum(asset.amount), currency.name, currency.unit}
    )
  end

  def info(:unit, unit) do
    from(asset in Money.Asset,
      join: currency in Money.Currency,
      on: asset.currency_id == currency.id,
      where: currency.unit == ^unit,
      group_by: currency.id,
      select:
        {sum(asset.amount), currency.name, currency.unit}
    )
  end

  def info(:id, id) do
    from(asset in Money.Asset,
      join: currency in Money.Currency,
      on: asset.currency_id == currency.id,
      where: currency.id == ^id,
      group_by: currency.id,
      select:
        {sum(asset.amount), currency.name, currency.unit}
    )
  end
end
