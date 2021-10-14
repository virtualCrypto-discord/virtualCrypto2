defmodule VirtualCrypto.Money.Query.Issue do
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  alias VirtualCrypto.Repo
  import VirtualCrypto.Money.Query.Util
  import VirtualCrypto.Money.Query.Asset, only: [upsert_asset_amount: 3]
  import VirtualCrypto.Money.Query.Currency, only: [update_pool_amount: 2,get_currency_by_guild_id_with_lock: 1]

  def issue(receiver, :all, guild_id) do
    # Get currency info by guild.
    with currency <- get_currency_by_guild_id_with_lock(guild_id),
         # Is currency exits?
         {:currency, true} <- {:currency, currency != nil},
         {:pool_amount, amount} when amount > 0 <- {:pool_amount, currency.pool_amount},
         # Insert receiver user if not exists.
         receiver_id <- UserResolvable.resolve_id(receiver),
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

  def issue(receiver, amount, guild_id)
      when is_positive_integer(amount) do
    # Get currency info by guild.
    with currency <- get_currency_by_guild_id_with_lock(guild_id),
         # Is currency exits?
         {:currency, true} <- {:currency, currency != nil},
         # Check pool amount enough.
         {:pool_amount, true} <- {:pool_amount, currency.pool_amount >= amount},
         # Insert receiver user if not exists.
         receiver_id <- UserResolvable.resolve_id(receiver),
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

  def issue(_receiver_discord_id, _amount, _guild_id) do
    {:error, :invalid_amount}
  end
end
