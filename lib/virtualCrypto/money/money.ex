defmodule VirtualCrypto.Money.Action do
  alias VirtualCrypto.Repo
  import Ecto.Query
  alias VirtualCrypto.Money

  def pay(sender_id, receiver_id, amount, money_unit) when is_integer(amount) and amount >= 1 do
    # Get money info by unit.
    with money <-
           Money.Info
           |> where([m], m.unit == ^money_unit)
           |> Repo.one(),
         # Is money exits?
         {:money, true} <- {:money, money != nil},
         # Get sender asset by sender id and money id.
         sender_asset <-
           Money.Asset
           |> where([a], a.user_id == ^sender_id and a.money_id == ^money.id)
           |> lock("FOR UPDATE")
           |> Repo.one(),
         # Is sender asset exsits?
         {:sender_asset, true} <- {:sender_asset, sender_asset != nil},
         # Has sender enough amount?
         {:sender_asset_amount, true} <- {:sender_asset_amount, sender_asset.amount >= amount},
         # Insert reciver user if not exists.
         {:ok, _} <- Repo.insert(%Money.User{id: receiver_id, status: 0}, on_conflict: :nothing),
         # Upsert receiver amount.
         {:ok, _} <-
           Repo.insert(
             %Money.Asset{
               user_id: receiver_id,
               money_id: money.id,
               amount: amount,
               status: 0
             },
             on_conflict: [set: [inc: amount]],
             conflict_target: [:user_id, :money_id]
           ) do

      # Update sender amount.
      Money.Asset
      |> where([a], a.id == ^sender_asset.id)
      |> update(set: [inc: ^(-amount)])
      |> Repo.update_all([])
    else
      {:money, false} -> {:error, :not_found_money}
      {:sender_asset, false} -> {:error, :not_found_sender_asset}
      {:sender_asset_amount, false} -> {:error, :not_enough_amount}
      err -> {:error, err}
    end
  end
end

defmodule VirtualCrypto.Money do
end
