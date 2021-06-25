defmodule VirtualCrypto.Money.Query.Claim do
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  alias VirtualCrypto.Exterior.User.Resolver, as: UserResolver
  alias VirtualCrypto.Money.Query.Claim.Raw.Get, as: RawGet
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  import Ecto.Query
  import VirtualCrypto.Money.Query.Util

  def get_claim_by_id(id) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        where: claim.id == ^id,
        select: %{claim: claim, currency: currency, claimant: claimant, payer: payer}
      )

    query |> Repo.one()
  end

  def get_claims(
        operator,
        statuses \\ ["pending", "approved", "canceled", "denied"]
      ) do
    RawGet.get_claims(UserResolvable.resolve_id(operator), statuses)
  end

  def get_claims(
        operator,
        statuses,
        sr_filter,
        related_user,
        :desc_claim_id
      ) do
    [operator_id, related_user_id] = UserResolver.resolve_ids([operator, related_user])
    RawGet.get_claims(operator_id, statuses, sr_filter, related_user_id, :desc_claim_id)
  end

  def get_claims(
        operator,
        statuses,
        sr_filter,
        :desc_claim_id,
        limit
      ) do
    operator_id = UserResolvable.resolve_id(operator)
    RawGet.get_claims(operator_id, statuses, sr_filter, :desc_claim_id, limit)
  end

  def get_claims(
        operator,
        statuses,
        sr_filter,
        related_user,
        order,
        pagination,
        limit
      ) do
    [operator_id, related_user_id] = UserResolver.resolve_ids([operator, related_user])

    RawGet.get_claims(operator_id, statuses, sr_filter, related_user_id, order, pagination, limit)
  end

  defp update_claim_status(claim_id, new_status) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    result =
      Money.Claim
      |> where([c], c.id == ^claim_id and c.status == "pending")
      |> update(set: [status: ^new_status, updated_at: ^now])
      |> select([c], {c})
      |> Repo.update_all([])

    case result do
      {0, _} -> {:error, :not_found}
      {1, [{c}]} -> {:ok, c}
    end
  end

  def approve_claim(claim_id) do
    update_claim_status(claim_id, "approved")
  end

  def deny_claim(claim_id) do
    update_claim_status(claim_id, "denied")
  end

  def cancel_claim(claim_id) do
    update_claim_status(claim_id, "canceled")
  end

  def create_claim(claimant, payer, unit, amount)
      when is_positive_integer(amount) and amount <= 9_223_372_036_854_775_807 do
    case Money.Currency |> where([i], i.unit == ^unit) |> Repo.one() do
      nil ->
        {:error, :not_found_currency}

      currency ->
        [claimant_user_id, payer_user_id] = UserResolver.resolve_ids([claimant, payer])

        {:ok, claim} =
          %Money.Claim{
            amount: amount,
            status: "pending",
            claimant_user_id: claimant_user_id,
            payer_user_id: payer_user_id,
            currency_id: currency.id
          }
          |> Repo.insert()

        {:ok, get_claim_by_id(claim.id)}
    end
  end

  def create_claim(_claimant_user_id, _payer_user_id, _unit, _amount) do
    {:error, :invalid_amount}
  end
end
