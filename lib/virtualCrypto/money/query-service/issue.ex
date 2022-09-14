defmodule VirtualCrypto.Money.Query.Issue do
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  alias VirtualCrypto.Repo
  import VirtualCrypto.Money.Query.Util
  import VirtualCrypto.Money.Query.Asset, only: [upsert_asset_amount: 3]

  import VirtualCrypto.Money.Query.Currency,
    only: [get_currency_by_id: 1]

  def issue(_receiver_discord_id, 0, _guild_id) do
    {:error, :invalid_amount}
  end

  def issue(receiver, amount, currency_id) do
    # Get currency info by guild.
    with currency <- get_currency_by_id(currency_id),
         # Is currency exits?
         {:currency, true} <- {:currency, currency != nil},
         # Insert receiver user if not exists.
         receiver_id <- UserResolvable.resolve_id(receiver),
         # Update receiver amount.
         {:ok, _} <- upsert_asset_amount(receiver_id, currency.id, amount),
         {:ok, _} <-
           Repo.insert(%VirtualCrypto.Money.GivenHistory{
             amount: amount,
             currency_id: currency.id,
             time: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
             receiver_id: receiver_id
           }) do
      {:ok, currency}
    else
      {:currency, false} -> {:error, :not_found_currency}
      {:pool_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end
end
