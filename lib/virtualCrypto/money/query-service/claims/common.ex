defmodule VirtualCrypto.Money.Query.Claim.Common do
  import Ecto.Query
  alias VirtualCrypto.Money

  defmacro select_metadata(claim_metadata) do
    quote do
      fragment(
        "COALESCE (?.metadata, '{}'::jsonb)",
        unquote(claim_metadata)
      )
    end
  end

  def claims_base_query(executor_user_id) do
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
      select: %{
        claim: claim,
        currency: currency,
        claimant: claimant,
        payer: payer,
        metadata: select_metadata(claim_metadata)
      }
    )
  end
end
