defmodule VirtualCryptoWeb.ConditionChecker do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.User.User
  alias VirtualCrypto.Money.Asset
  alias VirtualCrypto.Money.Info

  def get_amount(user, currency) do
    case Repo.get_by(Asset,
           user_id: Repo.get_by(User, discord_id: user).id,
           money_id: currency
         ) do
      nil -> 0
      %{amount: amount} -> amount
    end
  end
end
