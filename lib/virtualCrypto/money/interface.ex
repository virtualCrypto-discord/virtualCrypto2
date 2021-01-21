defmodule VirtualCrypto.Money do
  alias VirtualCrypto.Repo
  alias Ecto.Multi
  alias VirtualCrypto.Money.InternalAction, as: Action

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
    end
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
         |> Multi.run(:info, fn _, _ ->
           {:ok, Action.get_money_by_guild_id(guild)}
         end)
         |> Repo.transaction() do
      {:ok, %{info: info}} -> {:ok, info}
      {:error, :give, :not_found_money, _} -> {:error, :not_found_money}
      {:error, :give, :not_found_sender_asset, _} -> {:error, :not_found_sender_asset}
      {:error, :give, :not_enough_amount, _} -> {:error, :not_enough_amount}
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
          {:ok} | {:error, :guild} | {:error, :unit} | {:error, :name} | {:error, :retry_limit}
  def create(kw) do
    creator_amount = Keyword.fetch!(kw, :creator_amount)

    _create(
      Keyword.fetch!(kw, :guild),
      Keyword.fetch!(kw, :name),
      Keyword.fetch!(kw, :unit),
      Keyword.fetch!(kw, :creator),
      creator_amount,
      div(creator_amount + 199, 200),
      Keyword.get(kw, :retry_count, 5)
    )
  end

  @spec balance(module(), user: non_neg_integer()) :: [
          %{
            amount: non_neg_integer(),
            asset_status: non_neg_integer(),
            name: String.t(),
            unit: String.t(),
            guild: non_neg_integer(),
            money_status: non_neg_integer()
          }
        ]
  def balance(service, kw) do
    service.balance(Keyword.fetch!(kw, :user))
    |> Enum.map(fn {asset_amount, asset_status, info_name, info_unit, info_guild_id, info_status} ->
      %{
        amount: asset_amount,
        asset_status: asset_status,
        name: info_name,
        unit: info_unit,
        guild: info_guild_id,
        money_status: info_status
      }
    end)
  end

  @spec info(name: String.t(), unit: String.t(), guild: non_neg_integer()) ::
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
           {:guild, nil} <- {:guild, Keyword.get(kw, :guild)} do
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

  @spec get_pending_claims(module(), Integer.t()) ::
          {[VirtualCrypto.Money.Claim], [VirtualCrypto.Money.Claim]}
  def get_pending_claims(service, discord_user_id) do
    {sent, received} = service.get_claims(discord_user_id)

    sent_ = sent |> Enum.filter(fn claim -> claim.status == "pending" end)
    received_ = received |> Enum.filter(fn claim -> claim.status == "pending" end)
    {sent_, received_}
  end

  @spec get_all_claims(module(), Integer.t()) ::
          {[VirtualCrypto.Money.Claim], [VirtualCrypto.Money.Claim]}
  def get_all_claims(service, discord_user_id) do
    service.get_claims(discord_user_id)
  end

  @spec approve_claim(module(), Integer.t(), Integer.t()) ::
          {:ok}
          | {:error, :not_found}
          | {:error, :not_found_money}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def approve_claim(service, id, discord_user_id) do
    case Repo.transaction(fn ->
           claim = service.get_received_claim(id, discord_user_id)

           with true <- claim != nil,
                true <- claim.status == "pending",
                user <- VirtualCrypto.User.get_user_by_id(claim.claimant_user_id),
                info <- VirtualCrypto.Money.InternalAction.get_money_by_id(claim.money_info_id),
                {:ok, _} <-
                  VirtualCrypto.Money.InternalAction.pay(
                    claim.payer_user_id,
                    user.discord_id,
                    claim.amount,
                    info.unit
                  ),
                {:ok, _} <-
                  VirtualCrypto.Money.InternalAction.approve_claim(id, claim.payer_user_id) do
             {:ok}
           else
             false -> {:error, :not_found}
             nil -> {:error, :not_found}
             err -> err
           end
         end) do
      {:ok, v} -> v
      v -> v
    end
  end

  @spec cancel_claim(module(), Integer.t(), Integer.t()) ::
          {:ok}
          | {:error, :not_found}
  def cancel_claim(service, id, discord_user_id) do
    case Repo.transaction(fn ->
           claim = service.get_sent_claim(id, discord_user_id)

           with false <- claim == nil,
                true <- claim.status == "pending",
                {:ok, _} <-
                  VirtualCrypto.Money.InternalAction.cancel_claim(id, claim.payer_user_id) do
             {:ok}
           else
             false -> {:error, :not_found}
             nil -> {:error, :not_found}
             err -> err
           end
         end) do
      {:ok, v} -> v
      v -> v
    end
  end

  @spec deny_claim(module(), Integer.t(), Integer.t()) ::
          {:ok}
          | {:error, :not_found}
  def deny_claim(service, id, discord_user_id) do
    case Repo.transaction(fn ->
           claim = service.get_received_claim(id, discord_user_id)

           with false <- claim == nil,
                true <- claim.status == "pending",
                {:ok, _} <- VirtualCrypto.Money.InternalAction.deny_claim(id, claim.payer_user_id) do
             {:ok}
           else
             false -> {:error, :not_found}
             nil -> {:error, :not_found}
             err -> err
           end
         end) do
      {:ok, v} -> v
      v -> v
    end
  end

  @doc """
  payer must be discord user
  """
  @spec create_claim(module(), Integer.t(), Integer.t(), String.t(), Integer.t()) ::
          {:ok, VirtualCrypto.Money.Claim} | {:error, :money_not_found}
  def create_claim(service, claimant_id, payer_discord_user_id, unit, amount) do
    service.create_claim(claimant_id, payer_discord_user_id, unit, amount)
  end

  def get_claim_by_id(id) do
    Action.get_claim_by_id(id)
  end
end
