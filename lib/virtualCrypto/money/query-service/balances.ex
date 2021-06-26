defmodule VirtualCrypto.Money.Query.Balance do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.VirtualCrypto, as: VCUser
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  import Ecto.Query
  alias VirtualCrypto.Repo

  @moduledoc """
  Query service module for balances
  """

  @spec get_balances(UserResolvable.t()) :: [
          %{
            asset: %VirtualCrypto.Money.Asset{},
            currency: %VirtualCrypto.Money.Currency{}
          }
        ]
  @doc """
  Get user's balance.
  """
  def get_balances(%VCUser{id: user_id}) do
    q =
      from asset in Money.Asset,
        join: currency in Money.Currency,
        on: asset.currency_id == currency.id,
        on: asset.user_id == ^user_id,
        select: {asset, currency},
        order_by: currency.unit

    Repo.all(q)
  end

  def get_balances(%DiscordUser{id: discord_user_id}) do
    q =
      from asset in Money.Asset,
        join: currency in Money.Currency,
        on: asset.currency_id == currency.id,
        join: users in VirtualCrypto.User.User,
        on: users.discord_id == ^discord_user_id and users.id == asset.user_id,
        select: {asset, currency},
        order_by: currency.unit

    Repo.all(q)
  end

  def get_balances(resolvable) do
    get_balances(%VCUser{id: UserResolvable.resolve_id(resolvable)})
  end
end
