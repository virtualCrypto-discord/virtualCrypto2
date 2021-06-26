defmodule VirtualCrypto.Money.InternalAction do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  alias VirtualCrypto.User.User
  alias VirtualCrypto.Exterior.User.Resolver, as: UserResolver
  import VirtualCrypto.User
  import VirtualCrypto.Money.Query.Util
  import VirtualCrypto.Money.Query.Currency
  import Ecto.Query

  defp filled?(enumerable) do
    Enum.all?(enumerable, &(&1 != nil))
  end

  # FIXME: order of parameters
  def pay(sender_id, receiver_id, amount, currency_unit)
      when is_positive_integer(amount) do
    # Get currency info by unit.
    with currency <- get_currency_by_unit(currency_unit),
         # Is currency exits?
         {:currency, true} <- {:currency, currency != nil},
         # resolve ids
         [sender_id, receiver_id] = ids = UserResolver.resolve_ids([sender_id, receiver_id]),
         {:user_ids, true} <- {:user_ids, filled?(ids)},
         # Get sender asset by sender id and currency id.
         sender_asset <- get_asset_with_lock(sender_id, currency.id),
         # Is sender asset exists?
         {:sender_asset, true} <- {:sender_asset, sender_asset != nil},
         # Has sender enough amount?
         {:sender_asset_amount, true} <- {:sender_asset_amount, sender_asset.amount >= amount},
         # Upsert receiver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, currency.id, amount),
         # Update sender amount.
         {:ok, _} <- update_asset_amount(sender_asset.id, -amount),
         # recording histories
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
      {:user_ids, false} -> {:error, :not_found_user}
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

  def update_pool_amount(currency_id, amount) do
    {1, nil} =
      Money.Currency
      |> where([a], a.id == ^currency_id)
      |> update(inc: [pool_amount: ^amount])
      |> Repo.update_all([])

    {:ok, nil}
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
end
