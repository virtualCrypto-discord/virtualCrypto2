defmodule VirtualCrypto.Money.Query.Claim do
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  alias VirtualCrypto.Exterior.User.Resolver, as: UserResolver
  alias VirtualCrypto.Money.Query.Claim.Raw.Get, as: RawGet
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money
  import Ecto.Query
  import VirtualCrypto.Money.Query.Util
  import VirtualCrypto.Money.Query.Claim.Common, only: [select_metadata: 1]

  @upsert_metadata_on_conflict from(claim_metadata in Money.ClaimMetadata,
                                 update: [
                                   set: [
                                     metadata:
                                       fragment(
                                         "jsonb_strip_nulls(?.metadata || EXCLUDED.metadata)",
                                         claim_metadata
                                       )
                                   ]
                                 ]
                               )

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
        select: %{
          claim: claim,
          currency: currency,
          claimant: claimant,
          payer: payer
        }
      )

    query |> Repo.one()
  end

  def get_claim_by_id_with_lock(id) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        where: claim.id == ^id,
        select: %{
          claim: claim,
          currency: currency,
          claimant: claimant,
          payer: payer
        },
        lock: fragment("FOR UPDATE OF ?", claim)
      )

    query |> Repo.one()
  end

  def get_claim_by_id(executor_user_id, id) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        left_join: claim_metadata in VirtualCrypto.Money.ClaimMetadata,
        on:
          claim.id == claim_metadata.claim_id and
            claim_metadata.owner_user_id == ^executor_user_id,
        where: claim.id == ^id,
        select: %{
          claim: claim,
          currency: currency,
          claimant: claimant,
          payer: payer,
          metadata: select_metadata(claim_metadata)
        }
      )

    query |> Repo.one()
  end

  def get_claim_by_id_with_lock(executor_user_id, id) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        left_join: claim_metadata in VirtualCrypto.Money.ClaimMetadata,
        on:
          claim.id == claim_metadata.claim_id and
            claim_metadata.owner_user_id == ^executor_user_id,
        where: claim.id == ^id,
        select: %{
          claim: claim,
          currency: currency,
          claimant: claimant,
          payer: payer,
          metadata: select_metadata(claim_metadata)
        },
        lock: fragment("FOR UPDATE OF ?,?", claim, claim_metadata)
      )

    query |> Repo.one()
  end

  def get_claim_by_ids(ids) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        where: claim.id in ^ids,
        select: %{
          claim: claim,
          currency: currency,
          claimant: claimant,
          payer: payer
        }
      )

    result = query |> Repo.all() |> Map.new(fn %{claim: %{id: id}} = m -> {id, m} end)
    ids |> Enum.map(fn id -> Map.get(result, id) end)
  end

  def get_claim_by_ids_with_lock(ids) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        where: claim.id in ^ids,
        select: %{
          claim: claim,
          currency: currency,
          claimant: claimant,
          payer: payer
        },
        lock: fragment("FOR UPDATE OF ?", claim)
      )

    result = query |> Repo.all() |> Map.new(fn %{claim: %{id: id}} = m -> {id, m} end)
    ids |> Enum.map(fn id -> Map.get(result, id) end)
  end

  def get_claim_by_ids(executor_user_id, ids) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        left_join: claim_metadata in VirtualCrypto.Money.ClaimMetadata,
        on:
          claim.id == claim_metadata.claim_id and
            claim_metadata.owner_user_id == ^executor_user_id,
        where: claim.id in ^ids,
        select: %{
          claim: claim,
          currency: currency,
          claimant: claimant,
          payer: payer,
          metadata: select_metadata(claim_metadata)
        }
      )

    result = query |> Repo.all() |> Map.new(fn %{claim: %{id: id}} = m -> {id, m} end)
    ids |> Enum.map(fn id -> Map.get(result, id) end)
  end

  def get_claim_by_ids_with_lock(executor_user_id, ids) do
    query =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        left_join: claim_metadata in VirtualCrypto.Money.ClaimMetadata,
        on:
          claim.id == claim_metadata.claim_id and
            claim_metadata.owner_user_id == ^executor_user_id,
        where:
          claim.id in ^ids and
            (claim.payer_user_id == ^executor_user_id or
               claim.claimant_user_id == ^executor_user_id),
        select: %{
          claim: claim,
          currency: currency,
          claimant: claimant,
          payer: payer,
          metadata: select_metadata(claim_metadata)
        },
        lock: fragment("FOR UPDATE OF ?,?", claim, claim_metadata)
      )

    result = query |> Repo.all() |> Map.new(fn %{claim: %{id: id}} = m -> {id, m} end)
    ids |> Enum.map(fn id -> Map.get(result, id) end)
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

  def upsert_claims_metadata(
        operator_user_id,
        claim_claim_metadata_pair
      ) do
    case Repo.insert_all(
           Money.ClaimMetadata,
           claim_claim_metadata_pair
           |> Enum.map(fn {claim, metadata} ->
             %{
               claim_id: claim.id,
               payer_user_id: claim.payer_user_id,
               claimant_user_id: claim.claimant_user_id,
               owner_user_id: operator_user_id,
               metadata: metadata
             }
           end),
           on_conflict: @upsert_metadata_on_conflict,
           conflict_target: [:claim_id, :owner_user_id]
         ) do
      {:ok, _} ->
        {:ok, nil}

      {:error,
       %{errors: [metadata: {_, [constraint: :check, constraint_name: "metadata_limit"]}]}} ->
        {:error, :max_metadata_count}
    end
  end

  def delete_claims_metadata(operator_user_id, claim_ids) do
    Money.ClaimMetadata
    |> where([c], c.claim_id in ^claim_ids and c.owner_user_id == ^operator_user_id)
    |> Repo.delete_all()
  end

  def update_claims_metadata(operator_user_id, claim_claim_metadata_pair) do
    %{true => upsert, false => deleting} =
      %{true => [], false => []}
      |> Map.merge(
        claim_claim_metadata_pair
        |> Enum.group_by(fn {_k, metadata} -> metadata != nil end)
      )

    upsert_claims_metadata(operator_user_id, upsert)
    delete_claims_metadata(operator_user_id, deleting |> Enum.map(&elem(&1, 0).id))
  end

  def update_claims_status(claim_ids, new_status, time \\ nil) do
    time = (time || NaiveDateTime.utc_now()) |> NaiveDateTime.truncate(:second)

    {_, cs} =
      Money.Claim
      |> where([c], c.id in ^claim_ids and c.status == "pending")
      |> update(set: [status: ^new_status, updated_at: ^time])
      |> select([c], {c})
      |> Repo.update_all([])

    claims = cs |> Enum.map(&elem(&1, 0))

    {:ok, claims}
  end

  def get_claim_metadata(claim_id, operator_user_id) do
    case Money.ClaimMetadata
         |> select([c], %{metadata: c.metadata})
         |> where([c], c.claim_id == ^claim_id and c.owner_user_id == ^operator_user_id)
         |> Repo.one() do
      nil -> %{}
      %{metadata: metadata} -> metadata
    end
  end

  def get_claims_metadata(claim_ids, operator_user_id) do
    Money.ClaimMetadata
    |> select([c], %{claim_id: c.claim_id, metadata: c.metadata})
    |> where([c], c.claim_id in ^claim_ids and c.owner_user_id == ^operator_user_id)
    |> Repo.all()
  end

  def delete_claim_metadata(claim_id, operator_user_id) do
    Money.ClaimMetadata
    |> where([c], c.claim_id == ^claim_id and c.owner_user_id == ^operator_user_id)
    |> Repo.delete_all()
  end

  def upsert_claim_metadata(
        claim_id,
        payer_user_id,
        claimant_user_id,
        operator_user_id,
        metadata
      ) do
    try do
      case Repo.insert_all(
             Money.ClaimMetadata,
             [
               %{
                 claim_id: claim_id,
                 payer_user_id: payer_user_id,
                 claimant_user_id: claimant_user_id,
                 owner_user_id: operator_user_id,
                 metadata: metadata
               }
             ],
             on_conflict: @upsert_metadata_on_conflict,
             conflict_target: [:claim_id, :owner_user_id],
             returning: [:metadata]
           ) do
        {0, []} ->
          {:ok, %{}}

        {1, [%{metadata: m}]} ->
          {:ok, m}
      end
    rescue
      e in Postgrex.Error ->
        case e do
          %{
            postgres: %{
              code: :check_violation
            }
          } ->
            {:error, :metadata_limit}

          _ ->
            raise e
        end
    end
  end

  defp update_claim_status(operator_user_id, claim_id, new_status, nil) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    result =
      Money.Claim
      |> where([c], c.id == ^claim_id and c.status == "pending")
      |> update(set: [status: ^new_status, updated_at: ^now])
      |> select([c], {c})
      |> Repo.update_all([])

    delete_claim_metadata(claim_id, operator_user_id)

    case result do
      {0, _} -> {:error, :not_found}
      {1, [{c}]} -> {:ok, %{claim: c, metadata: %{}}}
    end
  end

  defp update_claim_status(operator_user_id, claim_id, new_status, metadata) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    result =
      Money.Claim
      |> where([c], c.id == ^claim_id and c.status == "pending")
      |> update(set: [status: ^new_status, updated_at: ^now])
      |> select([c], {c})
      |> Repo.update_all([])

    case result do
      {0, _} ->
        {:error, :not_found}

      {1, [{c}]} ->
        case upsert_claim_metadata(
               c.id,
               c.payer_user_id,
               c.claimant_user_id,
               operator_user_id,
               metadata
             ) do
          {:ok, metadata} ->
            {:ok,
             %{
               claim: c,
               metadata: metadata
             }}

          {:error, _} = d ->
            d
        end
    end
  end

  def approve_claim(operator_user_id, claim_id, metadata) do
    update_claim_status(operator_user_id, claim_id, "approved", metadata)
  end

  def deny_claim(operator_user_id, claim_id, metadata) do
    update_claim_status(operator_user_id, claim_id, "denied", metadata)
  end

  def cancel_claim(operator_user_id, claim_id, metadata) do
    update_claim_status(operator_user_id, claim_id, "canceled", metadata)
  end

  def create_claim(claimant, payer, unit, amount, metadata)
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

        if metadata do
          %Money.ClaimMetadata{
            claim_id: claim.id,
            claimant_user_id: claimant_user_id,
            payer_user_id: payer_user_id,
            owner_user_id: claimant_user_id,
            metadata: metadata
          }
          |> Repo.insert()
        end

        {:ok, get_claim_by_id(claimant_user_id, claim.id)}
    end
  end

  def create_claim(_claimant_user_id, _payer_user_id, _unit, _amount, _metadata) do
    {:error, :invalid_amount}
  end
end
