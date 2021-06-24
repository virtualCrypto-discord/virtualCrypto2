defmodule VirtualCrypto.Money.Query.GetClaim do
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  alias VirtualCrypto.Exterior.User.Resolver, as: UserResolver
  alias VirtualCrypto.Money.Query.GetClaim.Raw

  def get_claims(
        operator,
        statuses \\ ["pending", "approved", "canceled", "denied"]
      ) do
    Raw.get_claims(UserResolvable.resolve_id(operator), statuses)
  end

  def get_claims(
        operator,
        statuses,
        sr_filter,
        related_user,
        :desc_claim_id
      ) do
    [operator_id, related_user_id] = UserResolver.resolve_ids([operator, related_user])
    Raw.get_claims(operator_id, statuses, sr_filter, related_user_id, :desc_claim_id)
  end

  def get_claims(
        operator,
        statuses,
        sr_filter,
        :desc_claim_id,
        limit
      ) do
    operator_id = UserResolvable.resolve_id(operator)
    Raw.get_claims(operator_id, statuses, sr_filter, :desc_claim_id, limit)
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

    Raw.get_claims(operator_id, statuses, sr_filter, related_user_id, order, pagination, limit)
  end
end
