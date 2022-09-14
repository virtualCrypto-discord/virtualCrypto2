defmodule VirtualCryptoLegacyIssuer do
  alias VirtualCrypto.Repo
  alias VirtualCryptoLegacyIssuer.LegacyIssuer
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
  UPDATE legacy_issuer
  SET pool_amount =
    CASE
      WHEN schedules.increasing_pool_amount+pool_amount>schedules.pool_amount_limit THEN schedules.pool_amount_limit
      ELSE schedules.increasing_pool_amount+pool_amount
    END
  FROM schedules
  WHERE schedules.currency_id = legacy_issuer.currency_id
  ;
  """
  def reset_pool_amount() do
    Ecto.Adapters.SQL.query!(Repo, @reset_pool_amount)
  end

  def update_pool_amount(currency_id, amount) do
    {1, nil} =
      LegacyIssuer
      |> where([a], a.currency_id == ^currency_id)
      |> update(inc: [pool_amount: ^amount])
      |> Repo.update_all([])

    {:ok, nil}
  end

  def get_legacy_issuer_by_guild_id(guild_id) do
    LegacyIssuer
    |> where([m], m.guild_id == ^guild_id)
    |> Repo.one()
  end

  def get_legacy_issuer_by_guild_id_with_lock(guild_id) do
    LegacyIssuer
    |> where([m], m.guild_id == ^guild_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  def issue(%{guild: guild_id, receiver: receiver, amount: amount}) when amount > 0 do
    Repo.transaction(fn ->
      with {:get_issuer, legacy_issuer} when legacy_issuer != nil <-
             {:get_issuer, get_legacy_issuer_by_guild_id_with_lock(guild_id)},
           amount <-
             (if amount == :all do
                legacy_issuer.pool_amount
              else
                amount
              end),
           {:pool_amount, true} <- {:pool_amount, legacy_issuer.pool_amount >= amount},
           {:ok, nil} <- update_pool_amount(legacy_issuer.currency_id, -amount),
           {:ok, currency} <-
             VirtualCrypto.Money.issue_embedded_issuer_bypass(%{
               currency_id: legacy_issuer.currency_id,
               receiver: receiver,
               amount: amount
             }) do
        {:ok,
         %{
           currency: currency,
           amount: amount,
           issuer: %{legacy_issuer | pool_amount: legacy_issuer.pool_amount - amount}
         }}
      else
        {:get_issuer, nil} -> Repo.rollback(:not_found_currency)
        {:pool_amount, _} -> Repo.rollback(:not_enough_amount)
        {:error, err} -> Repo.rollback(err)
      end
    end)
  end

  def issue(_) do
    {:error, :invalid_amount}
  end

  def enact_monetary_system(%{
        name: name,
        unit: unit,
        creator: creator,
        creator_amount: creator_amount,
        guild: guild_id
      })
      when 0 <= creator_amount and creator_amount <= 4_294_967_295 do
    Repo.transaction(fn ->
      initial_pool_amount = max(div(creator_amount + 199, 200), 5)

      with {:guild, nil} <- {:guild, get_legacy_issuer_by_guild_id(guild_id)},
           {:ok, currency} <-
             VirtualCrypto.Money.enact_embedded_issuer_bypass(%{name: name, unit: unit}),
           {:ok, _} <-
             Repo.insert(%LegacyIssuer{
               currency_id: currency.id,
               pool_amount: initial_pool_amount,
               guild_id: guild_id
             }),
           {:ok, _} <-
             VirtualCrypto.Money.issue_embedded_issuer_bypass(%{
               currency_id: currency.id,
               receiver: creator,
               amount: creator_amount
             }) do
        nil
      else
        {:guild, _} -> Repo.rollback(:duplicate_guild)
        {:error, err} -> Repo.rollback(err)
      end
    end)
  end

  def enact_monetary_system(_) do
    {:error, :invalid_amount}
  end
end
