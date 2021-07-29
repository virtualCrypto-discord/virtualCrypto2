defmodule VirtualCrypto.Money.Query.Claim.Raw.Get do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Repo
  import Ecto.Query
  import VirtualCrypto.Money.Query.Claim.Common

  defp sr_filter(q, :all, user_id) do
    q
    |> where(
      [claim, currency, claimant, payer],
      claim.payer_user_id == ^user_id or claim.claimant_user_id == ^user_id
    )
  end

  defp sr_filter(q, :received, user_id) do
    q |> where([claim, currency, claimant, payer], claim.payer_user_id == ^user_id)
  end

  defp sr_filter(q, :claimed, user_id) do
    q |> where([claim, currency, claimant, payer], claim.claimant_user_id == ^user_id)
  end

  defmacrop get_claims_m_q(
              q,
              operator_id,
              statuses,
              sr_filter,
              related_user_id,
              order_by,
              cond_expr,
              limit \\ nil
            ) do
    q =
      quote do
        operator_id = unquote(operator_id)
        statuses = unquote(statuses)
        related_user_id = unquote(related_user_id)

        q =
          unquote(q)
          |> where(
            [claim, currency, claimant, payer],
            claim.status in ^statuses and unquote(cond_expr)
          )
          |> sr_filter(unquote(sr_filter), operator_id)

        q =
          case related_user_id do
            nil -> q
            related_user_id -> q |> sr_filter(:all, related_user_id)
          end

        q |> order_by([claim, info, claimant, payer], unquote(order_by))
      end

    case limit do
      nil ->
        q

      _ ->
        quote do
          limit = unquote(limit)

          case limit do
            {limit, offset} ->
              unquote(q)
              |> limit(^limit)
              |> offset(^offset)

            limit ->
              unquote(q)
              |> limit(^limit)
          end
        end
    end
  end

  @spec get_claims_m(
          non_neg_integer(),
          [String.t()],
          atom(),
          non_neg_integer(),
          :desc_claim_id,
          any(),
          nil | non_neg_integer() | {non_neg_integer(), non_neg_integer()}
        ) :: list(Money.claim_t())
  defmacrop get_claims_m(
              operator_id,
              statuses,
              sr_filter,
              related_user_id,
              order_by,
              cond_expr,
              limit \\ nil
            ) do
    quote do
      get_claims_m_q(
        claims_base_query(),
        unquote(operator_id),
        unquote(statuses),
        unquote(sr_filter),
        unquote(related_user_id),
        unquote(order_by),
        unquote(cond_expr),
        unquote(limit)
      )
      |> Repo.all()
    end
  end

  def get_claims(
        operator_id,
        statuses \\ ["pending", "approved", "canceled", "denied"]
      ) do
    get_claims(operator_id, statuses, :all, nil, :desc_claim_id)
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id
      ) do
    get_claims_m(operator_id, statuses, sr_filter, related_user_id, [desc: claim.id], ^true)
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        :desc_claim_id,
        limit
      ) do
    get_claims(
      operator_id,
      statuses,
      sr_filter,
      nil,
      :desc_claim_id,
      %{cursor: :first},
      limit
    )
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{page: :last},
        limit
      ) do
    q =
      from(claim in Money.Claim,
        join: currency in Money.Currency,
        join: claimant in VirtualCrypto.User.User,
        join: payer in VirtualCrypto.User.User,
        on:
          claim.payer_user_id == payer.id and claim.currency_id == currency.id and
            claim.claimant_user_id == claimant.id,
        select: count(claim.id)
      )

    [cnt] =
      get_claims_m_q(q, operator_id, statuses, sr_filter, related_user_id, [], ^true)
      |> Repo.all()

    page = div(cnt + limit - 1, limit)

    limit =
      case rem(cnt, limit) do
        0 -> limit
        x -> x
      end

    result =
      get_claims_m(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        [asc: claim.id],
        ^true,
        limit
      )

    {first, prev} = if cnt > limit, do: {1, page - 1}, else: {nil, nil}

    %{
      claims: result |> Enum.reverse(),
      next: nil,
      prev: prev,
      last: nil,
      first: first,
      page: page
    }
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{page: n},
        limit
      ) do
    result =
      get_claims_m(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        [desc: claim.id],
        ^true,
        {limit + 1, limit * (n - 1)}
      )

    prev? = n != 1
    next? = Enum.count(result) > limit
    {first, prev} = if prev?, do: {1, n - 1}, else: {nil, nil}
    {last, next} = if next?, do: {:last, n + 1}, else: {nil, nil}

    %{
      claims: result |> Enum.take(limit),
      next: next,
      prev: prev,
      last: last,
      first: first,
      page: n
    }
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{cursor: :first},
        limit
      ) do
    get_claims_m(
      operator_id,
      statuses,
      sr_filter,
      related_user_id,
      [desc: claim.id],
      ^true,
      limit
    )
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{cursor: {:next, x}},
        limit
      ) do
    get_claims_m(
      operator_id,
      statuses,
      sr_filter,
      related_user_id,
      [desc: claim.id],
      claim.id < ^x,
      limit
    )
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :asc_claim_id,
        %{cursor: :first},
        limit
      ) do
    get_claims_m(
      operator_id,
      statuses,
      sr_filter,
      related_user_id,
      [asc: claim.id],
      ^true,
      limit
    )
  end

  def get_claims(
        operator_id,
        statuses,
        sr_filter,
        related_user_id,
        :asc_claim_id,
        %{cursor: {:next, x}},
        limit
      ) do
    get_claims_m(
      operator_id,
      statuses,
      sr_filter,
      related_user_id,
      [asc: claim.id],
      claim.id > ^x,
      limit
    )
  end
end
