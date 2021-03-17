defmodule VirtualCrypto.Money do
  alias VirtualCrypto.Repo
  alias Ecto.Multi
  alias VirtualCrypto.Money.InternalAction, as: Action

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

  @spec info(name: String.t(), unit: String.t(), guild: non_neg_integer(),id: non_neg_integer()) ::
          %{
            amount: non_neg_integer(),
            name: String.t(),
            unit: String.t(),
            guild: non_neg_integer(),
            money_status: non_neg_integer(),
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
      {amount, info_name, info_unit, info_guild_id, info_status, pool_amount} ->
        %{
          amount: amount,
          name: info_name,
          unit: info_unit,
          guild: info_guild_id,
          money_status: info_status,
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

  # FIXME: this is not useful return value!
  @spec get_claims(module(), Integer.t(), String.t()) ::
          [
            {VirtualCrypto.Money.Claim, VirtualCrypto.Money.Info, VirtualCrypto.User.User,
             VirtualCrypto.User.User}
          ]
  def get_claims(service, user_id, status) do
    service.get_claims(user_id, status)
  end

  # FIXME: this is not useful return value!
  @spec get_claims(module(), Integer.t()) ::
          [
            {VirtualCrypto.Money.Claim, VirtualCrypto.Money.Info, VirtualCrypto.User.User,
             VirtualCrypto.User.User}
          ]
  def get_claims(service, user_id) do
    service.get_claims(user_id)
  end

  # FIXME: this is not useful return value!
  @spec approve_claim(module(), Integer.t(), Integer.t()) ::
          {:ok,
           {VirtualCrypto.Money.Claim, VirtualCrypto.Money.Info, VirtualCrypto.User.User,
            VirtualCrypto.User.User}}
          | {:error, :not_found}
          | {:error, :not_found_money}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def approve_claim(service, id, user_id) do
    case Repo.transaction(fn ->
           with {:get_received_claim,
                 {%VirtualCrypto.Money.Claim{status: "pending", amount: amount}, info, claimant,
                  payer}} <-
                  {:get_received_claim, service.get_received_claim(id, user_id)},
                {:ok, _} <-
                  VirtualCrypto.Money.InternalAction.pay(
                    payer.id,
                    claimant.discord_id,
                    amount,
                    info.unit
                  ),
                {:ok, claim} <-
                  VirtualCrypto.Money.InternalAction.approve_claim(id) do
             {claim, info, claimant, payer}
           else
             {:get_received_claim, _} -> Repo.rollback(:not_found)
             {:error, :not_found} -> Repo.rollback(:not_found)
             {:error, v} -> Repo.rollback(v)
           end
         end) do
      {:ok, v} -> {:ok, v}
      {:error, v} -> {:error, v}
    end
  end

  # FIXME: this is not useful return value!
  @spec cancel_claim(module(), Integer.t(), Integer.t()) ::
          {:ok,
           {VirtualCrypto.Money.Claim, VirtualCrypto.Money.Info, VirtualCrypto.User.User,
            VirtualCrypto.User.User}}
          | {:error, :not_found}
  def cancel_claim(service, id, user_id) do
    case Repo.transaction(fn ->
           with {:get_sent_claim,
                 {%VirtualCrypto.Money.Claim{status: "pending"}, info, claimant, payer}} <-
                  {:get_sent_claim, service.get_sent_claim(id, user_id)},
                {:ok, claim} <-
                  VirtualCrypto.Money.InternalAction.cancel_claim(id) do
             {claim, info, claimant, payer}
           else
             {:get_sent_claim, _} -> Repo.rollback(:not_found)
             {:error, :not_found} -> Repo.rollback(:not_found)
           end
         end) do
      {:ok, v} -> {:ok, v}
      {:error, v} -> {:error, v}
    end
  end

  # FIXME: this is not useful return value!
  @spec deny_claim(module(), Integer.t(), Integer.t()) ::
          {:ok,
           {VirtualCrypto.Money.Claim, VirtualCrypto.Money.Info, VirtualCrypto.User.User,
            VirtualCrypto.User.User}}
          | {:error, :not_found}
  def deny_claim(service, id, user_id) do
    case Repo.transaction(fn ->
           with {:get_received_claim,
                 {%VirtualCrypto.Money.Claim{status: "pending"}, info, claimant, payer}} <-
                  {:get_received_claim, service.get_received_claim(id, user_id)},
                {:ok, claim} <- VirtualCrypto.Money.InternalAction.deny_claim(id) do
             {claim, info, claimant, payer}
           else
             {:get_received_claim, _} -> Repo.rollback(:not_found)
             {:error, :not_found} -> Repo.rollback(:not_found)
           end
         end) do
      {:ok, v} -> {:ok, v}
      {:error, v} -> {:error, v}
    end
  end

  # FIXME: this is not useful input and return value!
  @doc """
  payer must be discord user
  """
  @spec create_claim(module(), Integer.t(), Integer.t(), String.t(), Integer.t()) ::
          {:ok,
           {VirtualCrypto.Money.Claim, VirtualCrypto.Money.Info, VirtualCrypto.User.User,
            VirtualCrypto.User.User}}
          | {:error, :money_not_found}
          | {:error, :invalid_amount}
  def create_claim(service, claimant_id, payer_discord_user_id, unit, amount) do
    service.create_claim(claimant_id, payer_discord_user_id, unit, amount)
  end

  # FIXME: this is not useful return value!
  @spec get_claim_by_id(Integer.t()) ::
          {:ok,
           {VirtualCrypto.Money.Claim, VirtualCrypto.Money.Info, VirtualCrypto.User.User,
            VirtualCrypto.User.User}}
          | {:error, :not_found}
  def get_claim_by_id(id) do
    Action.get_claim_by_id(id)
  end
end
