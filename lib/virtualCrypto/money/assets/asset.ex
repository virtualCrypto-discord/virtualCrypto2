defmodule VirtualCrypto.Money.Query.Asset do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Repo
  import Ecto.Query

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

  def get_asset_with_lock(user_id, currency_id) do
    Money.Asset
    |> where([a], a.user_id == ^user_id and a.currency_id == ^currency_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
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
end
