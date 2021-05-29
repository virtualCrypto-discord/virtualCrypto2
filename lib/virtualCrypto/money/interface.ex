defmodule VirtualCrypto.Money do
  alias VirtualCrypto.Repo
  alias Ecto.Multi
  alias VirtualCrypto.Money.InternalAction, as: Action

  @type claim_t :: %{
          claim: %VirtualCrypto.Money.Claim{},
          currency: %VirtualCrypto.Money.Info{},
          claimant: %VirtualCrypto.User.User{},
          payer: %VirtualCrypto.User.User{}
        }
  # FIXME: rename to create_payment and take map
  @moduledoc """
  receiver must be discord user
  """
  @spec pay(
          module(),
          sender: non_neg_integer(),
          receiver: non_neg_integer(),
          amount: non_neg_integer(),
          unit: String.t()
        ) ::
          {:ok}
          | {:error, :not_found_money}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
          | {:error, :invalid_amount}
  def pay(service, kw) do
    case Multi.new()
         |> Multi.run(:pay, fn _, _ ->
           service.pay(
             Keyword.fetch!(kw, :sender),
             Keyword.fetch!(kw, :receiver),
             Keyword.fetch!(kw, :amount),
             Keyword.fetch!(kw, :unit)
           )
         end)
         |> Repo.transaction() do
      {:ok, _} -> {:ok}
      {:error, :pay, :not_found_money, _} -> {:error, :not_found_money}
      {:error, :pay, :not_found_sender_asset, _} -> {:error, :not_found_sender_asset}
      {:error, :pay, :not_enough_amount, _} -> {:error, :not_enough_amount}
      {:error, :pay, :invalid_amount, _} -> {:error, :invalid_amount}
    end
  end

  def create_payments(sender_id, partial_payments, _kw \\ []) do
    Repo.transaction(fn ->
      r =
        with {:check_receiver_id_type, false} <-
               {:check_receiver_id_type,
                partial_payments
                |> Enum.any?(
                  &(Map.has_key?(&1, :receiver_discord_id) and Map.has_key?(&1, :receiver_id))
                )},
             m <-
               partial_payments |> Enum.group_by(&Map.has_key?(&1, :receiver_discord_id)),
             has_discord_id <- Map.get(m, true, []),
             has_not_discord_id <- Map.get(m, false, []),
             discord_ids <-
               MapSet.new(
                 has_discord_id
                 |> Enum.map(fn %{receiver_discord_id: receiver_discord_id} ->
                   receiver_discord_id
                 end)
               ),
             {:ok, returns} <-
               discord_ids
               |> MapSet.to_list()
               |> VirtualCrypto.User.insert_users_if_not_exists(),
             {:check_length, true} <-
               {:check_length, length(returns) == MapSet.size(discord_ids)},
             returns <-
               returns
               |> Enum.map(fn %{discord_id: discord_id, id: id} -> {discord_id, id} end)
               |> Map.new(),
             has_discord_id <-
               has_discord_id
               |> Enum.map(fn %{receiver_discord_id: receiver_discord_id} = partial_payment ->
                 partial_payment
                 |> Map.delete(:receiver_discord_id)
                 |> Map.put(:receiver_id, Map.get(returns, receiver_discord_id))
               end),
             partial_payments <- Enum.concat(has_discord_id, has_not_discord_id) do
          Action.bulk_pay(
            sender_id,
            partial_payments
            |> Enum.map(fn %{
                             receiver_id: receiver,
                             unit: unit,
                             amount: amount
                           } ->
              {unit, receiver, amount}
            end)
          )
        end

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
          | {:error, :not_found_money}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def give(kw) do
    guild = Keyword.fetch!(kw, :guild)

    case Multi.new()
         |> Multi.run(:give, fn _, _ ->
           Action.give(
             Keyword.fetch!(kw, :receiver),
             Keyword.fetch!(kw, :amount),
             guild
           )
         end)
         |> Repo.transaction() do
      {:ok, %{give: m}} -> {:ok, m}
      {:error, :give, :not_found_money, _} -> {:error, :not_found_money}
      {:error, :give, :not_found_sender_asset, _} -> {:error, :not_found_sender_asset}
      {:error, :give, :not_enough_amount, _} -> {:error, :not_enough_amount}
      {:error, :give, :invalid_amount, _} -> {:error, :invalid_amount}
    end
  end

  defp _create(guild, name, unit, creator, creator_amount, pool_amount, retry)
       when retry > 0 do
    case Multi.new()
         |> Multi.run(:create, fn _, _ ->
           Action.create(
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
          creator: non_neg_integer(),
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

    _create(
      Keyword.fetch!(kw, :guild),
      Keyword.fetch!(kw, :name),
      Keyword.fetch!(kw, :unit),
      Keyword.fetch!(kw, :creator),
      creator_amount,
      max(div(creator_amount + 199, 200), 5),
      Keyword.get(kw, :retry_count, 5)
    )
  end

  # TODO: separate this
  @spec balance(module(), user: non_neg_integer(), currency: non_neg_integer()) ::
          [
            %{
              asset: VirtualCrypto.Money.Asset,
              currency: VirtualCrypto.Money.Info
            }
          ]
          | %{
              asset: VirtualCrypto.Money.Asset,
              currency: VirtualCrypto.Money.Info
            }
          | nil
  def balance(service, kw) do
    case Keyword.fetch(kw, :currency) do
      {:ok, currency} ->
        case service.balance(Keyword.fetch!(kw, :user))
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
        service.balance(Keyword.fetch!(kw, :user))
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
        {atom, key} -> Repo.one(VirtualCrypto.Money.InternalAction.info(atom, key))
      end

    case raw do
      {amount, info_name, info_unit, info_guild_id, pool_amount} ->
        %{
          amount: Decimal.to_integer(amount),
          name: info_name,
          unit: info_unit,
          guild: info_guild_id,
          pool_amount: pool_amount
        }

      nil ->
        nil
    end
  end

  @spec reset_pool_amount() :: nil
  def reset_pool_amount() do
    VirtualCrypto.Money.InternalAction.reset_pool_amount()
    nil
  end

  # FIXME: take too many arguments
  @spec get_claims(
          module(),
          Integer.t(),
          [String.t()],
          :all | :received | :claimed,
          pos_integer(),
          :desc_claim_id,
          %{page: pos_integer() | :last} | %{cursor: {:after | :before, any()} | :first | :last},
          pos_integer()
        ) ::
          [
            claim_t
          ]
  def get_claims(
        service,
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
        service.get_claims(user_id, statuses, sr_filter,related_user_id, order_by, cursor, limit)
      end)

    x
  end

  @spec get_claims(module(), Integer.t(), [String.t()]) ::
          [
            claim_t
          ]
  def get_claims(service, user_id, statuses) do
    service.get_claims(user_id, statuses)
  end

  @spec get_claims(module(), Integer.t()) ::
          [
            claim_t
          ]
  def get_claims(service, user_id) do
    service.get_claims(user_id)
  end

  @spec approve_claim(module(), Integer.t(), Integer.t()) ::
          {:ok, claim_t}
          | {:error, :not_found}
          | {:error, :not_found_money}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def approve_claim(service, id, user_id) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{
                   claim: %{status: status, amount: amount},
                   currency: currency,
                   claimant: claimant,
                   payer: payer
                 }} <-
                  {:get_claim, Action.get_claim_by_id(id)},
                {:validate_operator, true} <-
                  {:validate_operator, service.equals?(payer, user_id)},
                {:status, "pending"} <- {:status, status},
                {:ok, _} <-
                  VirtualCrypto.Money.InternalAction.pay(
                    payer.id,
                    claimant.discord_id,
                    amount,
                    currency.unit
                  ),
                {:ok, claim} <-
                  VirtualCrypto.Money.InternalAction.approve_claim(id) do
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

  @spec cancel_claim(module(), Integer.t(), Integer.t()) ::
          {:ok, claim_t}
          | {:error, :not_found}
  def cancel_claim(service, id, user_id) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{claim: %{status: status}, currency: currency, claimant: claimant, payer: payer}} <-
                  {:get_claim, Action.get_claim_by_id(id)},
                {:validate_operator, true} <-
                  {:validate_operator, service.equals?(claimant, user_id)},
                {:status, "pending"} <- {:status, status},
                {:ok, claim} <- VirtualCrypto.Money.InternalAction.cancel_claim(id) do
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

  @spec deny_claim(module(), Integer.t(), Integer.t()) ::
          {:ok, claim_t}
          | {:error, :not_found}
  def deny_claim(service, id, user_id) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{claim: %{status: status}, currency: currency, claimant: claimant, payer: payer}} <-
                  {:get_claim, Action.get_claim_by_id(id)},
                {:validate_operator, true} <-
                  {:validate_operator, service.equals?(payer, user_id)},
                {:status, "pending"} <- {:status, status},
                {:ok, claim} <- VirtualCrypto.Money.InternalAction.deny_claim(id) do
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
  @spec create_claim(module(), Integer.t(), Integer.t(), String.t(), Integer.t()) ::
          {:ok, claim_t}
          | {:error, :money_not_found}
          | {:error, :invalid_amount}
  def create_claim(service, claimant_id, payer_discord_user_id, unit, amount) do
    service.create_claim(claimant_id, payer_discord_user_id, unit, amount)
  end

  @spec get_claim_by_id(Integer.t()) :: claim_t | {:error, :not_found}
  def get_claim_by_id(id) do
    Action.get_claim_by_id(id)
  end
end
