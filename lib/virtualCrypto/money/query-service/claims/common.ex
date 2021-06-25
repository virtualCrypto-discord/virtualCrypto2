defmodule VirtualCrypto.Money.Query.Claim.Common do
  import Ecto.Query
  alias VirtualCrypto.Money

  def claims_base_query do
    from(claim in Money.Claim,
      join: currency in Money.Currency,
      join: claimant in VirtualCrypto.User.User,
      join: payer in VirtualCrypto.User.User,
      on:
        claim.payer_user_id == payer.id and claim.currency_id == currency.id and
          claim.claimant_user_id == claimant.id,
      select: %{claim: claim, currency: currency, claimant: claimant, payer: payer}
    )
  end
end
