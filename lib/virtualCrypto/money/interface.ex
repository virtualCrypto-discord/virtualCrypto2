defmodule VirtualCrypto.Money do
  alias VirtualCrypto.Repo
  alias Ecto.Multi
  alias VirtualCrypto.Money.Query
  alias VirtualCrypto.Exterior.User.VirtualCrypto, as: VCUser
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCrypto.Exterior.User.Resolver, as: UserResolver
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable

  @type claim_t :: %{
          claim: %VirtualCrypto.Money.Claim{},
          currency: %VirtualCrypto.Money.Currency{},
          claimant: %VirtualCrypto.User.User{},
          payer: %VirtualCrypto.User.User{}
        }
  @type page :: pos_integer() | :last
  # FIXME: rename to create_payment and take map
  @moduledoc """
  receiver must be discord user
  """
  @spec pay(
          sender: UserResolvable.t(),
          receiver: UserResolvable.t(),
          amount: non_neg_integer(),
          unit: String.t()
        ) ::
          {:ok}
          | {:error, :not_found_currency}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
          | {:error, :invalid_amount}
  def pay(kw) do
    case Multi.new()
         |> Multi.run(:pay, fn _, _ ->
           VirtualCrypto.Money.Query.Asset.Transfer.transfer(
             Keyword.fetch!(kw, :sender),
             Keyword.fetch!(kw, :receiver),
             Keyword.fetch!(kw, :amount),
             Keyword.fetch!(kw, :unit)
           )
         end)
         |> Repo.transaction() do
      {:ok, _} -> {:ok}
      {:error, :pay, :not_found_currency, _} -> {:error, :not_found_currency}
      {:error, :pay, :not_found_sender_asset, _} -> {:error, :not_found_sender_asset}
      {:error, :pay, :not_found_user, _} -> {:error, :not_found_user}
      {:error, :pay, :not_enough_amount, _} -> {:error, :not_enough_amount}
      {:error, :pay, :invalid_amount, _} -> {:error, :invalid_amount}
    end
  end

  @spec create_payments(UserResolvable.t(), [
          %{
            receiver: UserResolvable.t(),
            unit: String.t(),
            amount: pos_integer()
          }
        ]) ::
          {:ok, nil} | {:error, :invalid_amount} | {:error, :not_enough_amount} | {:error, atom()}
  def create_payments(sender, partial_payments, _kw \\ []) do
    Repo.transaction(fn ->
      {receivers, partial_payments} =
        partial_payments |> Enum.map(fn m -> Map.pop!(m, :receiver) end) |> Enum.unzip()

      [sender_id | receiver_ids] = UserResolver.resolve_ids([sender | receivers])

      partial_payments =
        receiver_ids
        |> Enum.zip(partial_payments)
        |> Enum.map(fn {receiver_id, partial_payment} ->
          Map.put_new(partial_payment, :receiver_id, receiver_id)
        end)

      r =
        VirtualCrypto.Money.Query.Asset.Transfer.transfer_bulk(
          sender_id,
          partial_payments
          |> Enum.map(fn %{
                           receiver_id: receiver_id,
                           unit: unit,
                           amount: amount
                         } ->
            {unit, receiver_id, amount}
          end)
        )

      case r do
        {:ok, _} -> nil
        {:error, err} -> Repo.rollback(err)
      end
    end)
  end

  @doc """
  receiver must be discord user!
  """
  @spec give(
          receiver: non_neg_integer(),
          amount: non_neg_integer(),
          guild: non_neg_integer()
        ) ::
          {:ok, Ecto.Schema.t()}
          | {:error, :not_found_currency}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def give(kw) do
    guild = Keyword.fetch!(kw, :guild)

    case Multi.new()
         |> Multi.run(:give, fn _, _ ->
           VirtualCrypto.Money.Query.Issue.issue(
             Keyword.fetch!(kw, :receiver),
             Keyword.fetch!(kw, :amount),
             guild
           )
         end)
         |> Repo.transaction() do
      {:ok, %{give: m}} -> {:ok, m}
      {:error, :give, :not_found_currency, _} -> {:error, :not_found_currency}
      {:error, :give, :not_found_sender_asset, _} -> {:error, :not_found_sender_asset}
      {:error, :give, :not_enough_amount, _} -> {:error, :not_enough_amount}
      {:error, :give, :invalid_amount, _} -> {:error, :invalid_amount}
    end
  end

  defp _create(guild, name, unit, creator, creator_amount, pool_amount, retry)
       when retry > 0 do
    case Multi.new()
         |> Multi.run(:create, fn _, _ ->
           VirtualCrypto.Money.Query.Currency.create(
             guild,
             name,
             unit,
             creator,
             creator_amount,
             pool_amount
           )
         end)
         |> Repo.transaction() do
      {:ok, _} ->
        {:ok}

      {:error, :create, :guild, _} ->
        {:error, :guild}

      {:error, :create, :invalid_amount, _} ->
        {:error, :invalid_amount}

      {:error, :create, :unit, _} ->
        {:error, :unit}

      {:error, :create, :name, _} ->
        {:error, :name}

      {:error, _, _, _} ->
        _create(guild, name, unit, creator, creator_amount, pool_amount, retry - 1)
    end
  end

  defp _create(_, _, _, _, _, _, _) do
    {:error, :retry_limit}
  end

  @doc """
  Only calls discord context!
  """
  @spec create(
          guild: non_neg_integer(),
          name: String.t(),
          unit: String.t(),
          retry_count: pos_integer(),
          creator: DiscordUser.t(),
          creator_amount: pos_integer()
        ) ::
          {:ok}
          | {:error, :guild}
          | {:error, :unit}
          | {:error, :name}
          | {:error, :retry_limit}
          | {:error, :invalid_amount}
  def create(kw) do
    creator_amount = Keyword.fetch!(kw, :creator_amount)
    creator = Keyword.fetch!(kw, :creator)

    _create(
      Keyword.fetch!(kw, :guild),
      Keyword.fetch!(kw, :name),
      Keyword.fetch!(kw, :unit),
      creator,
      creator_amount,
      max(div(creator_amount + 199, 200), 5),
      Keyword.get(kw, :retry_count, 5)
    )
  end

  # TODO: separate this
  @spec balance(user: UserResolvable.t(), currency: non_neg_integer()) ::
          [
            %{
              asset: %VirtualCrypto.Money.Asset{},
              currency: %VirtualCrypto.Money.Currency{}
            }
          ]
          | %{
              asset: %VirtualCrypto.Money.Asset{},
              currency: %VirtualCrypto.Money.Currency{}
            }
          | nil
  def balance(kw) do
    case Keyword.fetch(kw, :currency) do
      {:ok, currency} ->
        case Query.Balance.get_balances(Keyword.fetch!(kw, :user))
             |> Enum.find(fn {_asset, currency_} -> currency_.id == currency end) do
          {asset, currency} ->
            %{
              asset: asset,
              currency: currency
            }

          nil ->
            nil
        end

      :error ->
        Query.Balance.get_balances(Keyword.fetch!(kw, :user))
        |> Enum.map(fn {asset, currency} ->
          %{
            asset: asset,
            currency: currency
          }
        end)
    end
  end

  @spec info(name: String.t(), unit: String.t(), guild: non_neg_integer(), id: non_neg_integer()) ::
          %{
            amount: non_neg_integer(),
            name: String.t(),
            unit: String.t(),
            guild: non_neg_integer(),
            pool_amount: non_neg_integer()
          }
          | nil
  def info(kw) do
    raw =
      with {:name, nil} <- {:name, Keyword.get(kw, :name)},
           {:unit, nil} <- {:unit, Keyword.get(kw, :unit)},
           {:guild, nil} <- {:guild, Keyword.get(kw, :guild)},
           {:id, nil} <- {:id, Keyword.get(kw, :id)} do
        raise "Invalid Argument. Must supply one or more arguments."
      else
        {atom, key} -> Repo.one(VirtualCrypto.Money.Query.Currency.info(atom, key))
      end

    case raw do
      {amount, currency_name, currency_unit, currency_guild_id, pool_amount} ->
        %{
          amount: Decimal.to_integer(amount),
          name: currency_name,
          unit: currency_unit,
          guild: currency_guild_id,
          pool_amount: pool_amount
        }

      nil ->
        nil
    end
  end

  @spec reset_pool_amount() :: nil
  def reset_pool_amount() do
    VirtualCrypto.Money.Query.Currency.reset_pool_amount()
    nil
  end

  # FIXME: take too many arguments
  @spec get_claims(
          UserResolvable.t(),
          [String.t()],
          :all | :received | :claimed,
          UserResolvable.t(),
          :desc_claim_id,
          %{page: page()} | %{cursor: {:after | :before, any()} | :first | :last},
          pos_integer() | {pos_integer(), pos_integer()} | nil
        ) ::
          %{
            claims: [
              claim_t
            ],
            next: page(),
            prev: page(),
            last: page(),
            first: page(),
            page: pos_integer()
          }

  def get_claims(
        user_id,
        statuses,
        sr_filter,
        related_user_id,
        order_by,
        cursor,
        limit
      ) do
    {:ok, x} =
      Repo.transaction(fn ->
        Query.Claim.get_claims(
          user_id,
          statuses,
          sr_filter,
          related_user_id,
          order_by,
          cursor,
          limit
        )
      end)

    x
  end

  @spec get_claims(UserResolvable.t(), [String.t()]) ::
          [
            claim_t
          ]
  def get_claims(user_id, statuses) do
    {:ok, x} =
      Repo.transaction(fn ->
        Query.Claim.get_claims(user_id, statuses)
      end)

    x
  end

  @spec get_claims(UserResolvable.t()) ::
          [
            claim_t
          ]
  def get_claims(user_id) do
    {:ok, x} =
      Repo.transaction(fn ->
        Query.Claim.get_claims(user_id)
      end)

    x
  end

  @spec approve_claim(non_neg_integer(), UserResolvable.t()) ::
          {:ok, claim_t}
          | {:error, :not_found}
          | {:error, :not_found_currency}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def approve_claim(id, operator) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{
                   claim: %{status: status, amount: amount},
                   currency: currency,
                   claimant: claimant,
                   payer: payer
                 }} <-
                  {:get_claim, VirtualCrypto.Money.Query.Claim.get_claim_by_id(id)},
                {:validate_operator, true} <-
                  {:validate_operator, UserResolvable.is?(operator, payer)},
                {:status, "pending"} <- {:status, status},
                {:ok, _} <-
                  VirtualCrypto.Money.Query.Asset.Transfer.transfer(
                    %VCUser{id: payer.id},
                    %VCUser{id: claimant.id},
                    amount,
                    currency.unit
                  ),
                {:ok, claim} <-
                  VirtualCrypto.Money.Query.Claim.approve_claim(id) do
             %{claim: claim, currency: currency, claimant: claimant, payer: payer}
           else
             {:get_claim, _} ->
               Repo.rollback(:not_found)

             {:validate_operator, _} ->
               Repo.rollback(:invalid_operator)

             {:status, _} ->
               Repo.rollback(:invalid_status)

             {:error, :not_found} ->
               Repo.rollback(:not_found)

             {:error, v} ->
               Repo.rollback(v)
           end
         end) do
      {:ok, v} -> {:ok, v}
      {:error, v} -> {:error, v}
    end
  end

  @spec cancel_claim(non_neg_integer(), UserResolvable.t()) ::
          {:ok, claim_t}
          | {:error, :not_found}
  def cancel_claim(id, operator) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{claim: %{status: status}, currency: currency, claimant: claimant, payer: payer}} <-
                  {:get_claim, VirtualCrypto.Money.Query.Claim.get_claim_by_id(id)},
                {:validate_operator, true} <-
                  {:validate_operator, UserResolvable.is?(operator, claimant)},
                {:status, "pending"} <- {:status, status},
                {:ok, claim} <- VirtualCrypto.Money.Query.Claim.cancel_claim(id) do
             %{claim: claim, currency: currency, claimant: claimant, payer: payer}
           else
             {:get_claim, _} ->
               Repo.rollback(:not_found)

             {:status, _} ->
               Repo.rollback(:invalid_status)

             {:validate_operator, _} ->
               Repo.rollback(:invalid_operator)

             {:error, :not_found} ->
               Repo.rollback(:not_found)
           end
         end) do
      {:ok, v} -> {:ok, v}
      {:error, v} -> {:error, v}
    end
  end

  @spec deny_claim(non_neg_integer(), UserResolvable.t()) ::
          {:ok, claim_t}
          | {:error, :not_found}
  def deny_claim(id, operator) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{claim: %{status: status}, currency: currency, claimant: claimant, payer: payer}} <-
                  {:get_claim, VirtualCrypto.Money.Query.Claim.get_claim_by_id(id)},
                {:validate_operator, true} <-
                  {:validate_operator, UserResolvable.is?(operator, payer)},
                {:status, "pending"} <- {:status, status},
                {:ok, claim} <- VirtualCrypto.Money.Query.Claim.deny_claim(id) do
             %{claim: claim, currency: currency, claimant: claimant, payer: payer}
           else
             {:get_claim, _} ->
               Repo.rollback(:not_found)

             {:status, _} ->
               Repo.rollback(:invalid_status)

             {:validate_operator, _} ->
               Repo.rollback(:invalid_operator)

             {:error, :not_found} ->
               Repo.rollback(:not_found)
           end
         end) do
      {:ok, v} -> {:ok, v}
      {:error, v} -> {:error, v}
    end
  end

  @doc """
  payer must be discord user
  """
  @spec create_claim(UserResolvable.t(), UserResolvable.t(), String.t(), pos_integer()) ::
          {:ok, claim_t}
          | {:error, :not_found_currency}
          | {:error, :invalid_amount}
  def create_claim(claimant, payer, unit, amount) do
    {:ok, x} =
      Repo.transaction(fn ->
        VirtualCrypto.Money.Query.Claim.create_claim(claimant, payer, unit, amount)
      end)

    x
  end

  @spec get_claim_by_id(non_neg_integer()) :: claim_t | {:error, :not_found}
  def get_claim_by_id(id) do
    {:ok, x} =
      Repo.transaction(fn ->
        VirtualCrypto.Money.Query.Claim.get_claim_by_id(id)
      end)

    x
  end
end
