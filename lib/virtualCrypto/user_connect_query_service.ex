defmodule VirtualCrypto.ConnectUser do
  alias VirtualCrypto.Repo
  import Ecto.Query

  def set_discord_user_id(application_user_id, discord_id) do
    Repo.transaction(fn ->
      case Repo.get_by(VirtualCrypto.User.User, discord_id: discord_id) do
        nil ->
          nil

        %VirtualCrypto.User.User{application_id: nil, id: source_user_id} ->
          _merge(application_user_id, source_user_id)

        _ ->
          Repo.rollback(:conflicted_user_id)
      end

      case VirtualCrypto.User.User
           |> where([u], u.id == ^application_user_id)
           |> update(set: [discord_id: ^discord_id])
           |> Repo.update_all([]) do
        {1, _} -> nil
        {_, _} -> Repo.rollback(:illegal_state)
      end
    end)
  end

  defp _merge(base_user_id, source_user_id) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # merge base_user and from_user asset
    {_, assets} =
      Repo.delete_all(
        from(assets in VirtualCrypto.Money.Asset,
          where: assets.user_id == ^source_user_id,
          select: {assets.currency_id, assets.amount}
        )
      )

    Repo.insert_all(
      VirtualCrypto.Money.Asset,
      assets
      |> Enum.map(fn {currency_id, amount} ->
        [
          amount: amount,
          user_id: base_user_id,
          currency_id: currency_id,
          inserted_at: now,
          updated_at: now
        ]
      end),
      on_conflict:
        from(assets in VirtualCrypto.Money.Asset,
          update: [
            inc: [amount: fragment("EXCLUDED.amount")],
            set: [user_id: ^base_user_id, updated_at: ^now]
          ]
        ),
      conflict_target: [:currency_id, :user_id]
    )

    # replace user_id of histories
    Repo.update_all(
      from(histories in VirtualCrypto.Money.GivenHistory,
        where: histories.receiver_id == ^source_user_id,
        update: [set: [receiver_id: ^base_user_id]]
      ),
      []
    )

    Repo.update_all(
      from(histories in VirtualCrypto.Money.PaymentHistory,
        where: histories.receiver_id == ^source_user_id,
        update: [set: [receiver_id: ^base_user_id]]
      ),
      []
    )

    Repo.update_all(
      from(histories in VirtualCrypto.Money.PaymentHistory,
        where: histories.sender_id == ^source_user_id,
        update: [set: [sender_id: ^base_user_id]]
      ),
      []
    )

    # replace user_id of claims
    Repo.update_all(
      from(claims in VirtualCrypto.Money.Claim,
        where: claims.claimant_user_id == ^source_user_id,
        update: [set: [claimant_user_id: ^base_user_id]]
      ),
      []
    )

    Repo.update_all(
      from(claims in VirtualCrypto.Money.Claim,
        where: claims.payer_user_id == ^source_user_id,
        update: [set: [payer_user_id: ^base_user_id]]
      ),
      []
    )

    Repo.delete_all(
      from(idempotency_entries in VirtualCrypto.Idempotency.Payments,
        where: idempotency_entries.user_id == ^source_user_id
      )
    )

    Repo.delete_all(from(users in VirtualCrypto.User.User, where: users.id == ^source_user_id))
  end
end
