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
  @type partial_claim_t :: %{
          id: non_neg_integer(),
          status: VirtualCrypto.Money.Claim.status_t()
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

  defp create_payments_(sender, partial_payments) do
    {receivers, partial_payments} =
      partial_payments |> Enum.map(fn m -> Map.pop!(m, :receiver) end) |> Enum.unzip()

    [sender_id | receiver_ids] = UserResolver.resolve_ids([sender | receivers])

    partial_payments =
      receiver_ids
      |> Enum.zip(partial_payments)
      |> Enum.map(fn {receiver_id, partial_payment} ->
        Map.put_new(partial_payment, :receiver_id, receiver_id)
      end)

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
      r = create_payments_(sender, partial_payments)

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
          receiver: UserResolvable.t(),
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
    {:ok, x} =
      Repo.transaction(fn ->
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
      end)

    x
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
          :desc_claim_id | :asc_claim_id,
          %{page: page()} | %{cursor: {:next, any()} | {:on_next, any()} | :first},
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
          | [claim_t()]

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

  defp format_claim_for_notification(%{
         claim: claim,
         currency: currency,
         payer: payer,
         metadata: metadata
       }) do
    %{
      id: claim.id,
      status:
        case claim.status do
          "approved" -> :approved
          "denied" -> :denied
        end,
      amount: to_string(claim.amount),
      updated_at: claim.updated_at |> DateTime.from_naive!("Etc/UTC"),
      metadata: metadata,
      payer: %{
        id: payer.id,
        discord: %{
          id:
            if payer.discord_id do
              to_string(payer.discord_id)
            else
              nil
            end
        }
      },
      currency: %{
        id: currency.id,
        unit: currency.unit,
        name: currency.name,
        guild: to_string(currency.guild_id),
        pool_amount: to_string(currency.pool_amount)
      }
    }
  end

  @spec approve_claim(non_neg_integer(), UserResolvable.t(), map() | nil) ::
          {:ok, claim_t}
          | {:error, :not_found}
          | {:error, :not_found_currency}
          | {:error, :not_found_sender_asset}
          | {:error, :not_enough_amount}
  def approve_claim(id, operator, metadata) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{
                   claim: %{status: status, amount: amount},
                   currency: currency,
                   claimant: claimant,
                   payer: payer
                 }} <-
                  {:get_claim, VirtualCrypto.Money.Query.Claim.get_claim_by_id_with_lock(id)},
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
                {:ok, %{claim: claim, metadata: metadata}} <-
                  VirtualCrypto.Money.Query.Claim.approve_claim(payer.id, id, metadata) do
             %{
               claim: claim,
               currency: currency,
               claimant: claimant,
               payer: payer,
               metadata: metadata,
               claimant_metadata:
                 VirtualCrypto.Money.Query.Claim.get_claim_metadata(claim.id, claimant.id)
             }
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
      {:ok, v} ->
        {claimant_metadata, v} = Map.pop!(v, :claimant_metadata)

        VirtualCrypto.Notification.Dispatcher.notify_claim_update(v.claimant, [
          format_claim_for_notification(%{v | metadata: claimant_metadata})
        ])

        {:ok, v}

      {:error, v} ->
        {:error, v}
    end
  end

  @spec cancel_claim(non_neg_integer(), UserResolvable.t(), map() | nil) ::
          {:ok, claim_t}
          | {:error, :not_found}
  def cancel_claim(id, operator, metadata) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{claim: %{status: status}, currency: currency, claimant: claimant, payer: payer}} <-
                  {:get_claim, VirtualCrypto.Money.Query.Claim.get_claim_by_id_with_lock(id)},
                {:validate_operator, true} <-
                  {:validate_operator, UserResolvable.is?(operator, claimant)},
                {:status, "pending"} <- {:status, status},
                {:ok, %{claim: claim, metadata: metadata}} <-
                  VirtualCrypto.Money.Query.Claim.cancel_claim(claimant.id, id, metadata) do
             %{
               claim: claim,
               currency: currency,
               claimant: claimant,
               payer: payer,
               metadata: metadata
             }
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
      {:ok, v} ->
        {:ok, v}

      {:error, v} ->
        {:error, v}
    end
  end

  @spec deny_claim(non_neg_integer(), UserResolvable.t(), map() | nil) ::
          {:ok, claim_t}
          | {:error, :not_found}
  def deny_claim(id, operator, metadata) do
    case Repo.transaction(fn ->
           with {:get_claim,
                 %{claim: %{status: status}, currency: currency, claimant: claimant, payer: payer}} <-
                  {:get_claim, VirtualCrypto.Money.Query.Claim.get_claim_by_id_with_lock(id)},
                {:validate_operator, true} <-
                  {:validate_operator, UserResolvable.is?(operator, payer)},
                {:status, "pending"} <- {:status, status},
                {:ok, %{claim: claim, metadata: metadata}} <-
                  VirtualCrypto.Money.Query.Claim.deny_claim(payer.id, id, metadata) do
             %{
               claim: claim,
               currency: currency,
               claimant: claimant,
               payer: payer,
               metadata: metadata,
               claimant_metadata:
                 VirtualCrypto.Money.Query.Claim.get_claim_metadata(claim.id, claimant.id)
             }
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
      {:ok, v} ->
        {claimant_metadata, v} = Map.pop!(v, :claimant_metadata)

        VirtualCrypto.Notification.Dispatcher.notify_claim_update(v.claimant, [
          format_claim_for_notification(%{v | metadata: claimant_metadata})
        ])

        {:ok, v}

      {:error, v} ->
        {:error, v}
    end
  end

  @spec update_metadata(non_neg_integer(), UserResolvable.t(), map() | nil) ::
          {:ok, claim_t}
          | {:error, :not_found}
  def update_metadata(id, operator, metadata) do
    case validate_metadata(metadata) do
      [] ->
        Repo.transaction(fn ->
          case Repo.get(VirtualCrypto.Money.Claim, id) do
            nil ->
              Repo.rollback(:not_found)

            claim ->
              operator_id = UserResolvable.resolve_id(operator)

              if operator_id in [claim.payer_user_id, claim.claimant_user_id] do
                metadata =
                  if metadata do
                    case VirtualCrypto.Money.Query.Claim.upsert_claim_metadata(
                           claim.id,
                           claim.payer_user_id,
                           claim.claimant_user_id,
                           operator_id,
                           metadata
                         ) do
                      {:ok, metadata} -> metadata
                      {:error, x} -> Repo.rollback(x)
                    end
                  else
                    VirtualCrypto.Money.Query.Claim.delete_claim_metadata(
                      claim.id,
                      operator_id
                    )

                    %{}
                  end

                VirtualCrypto.Money.Query.Claim.get_claim_by_id(claim.id)
                |> Map.put(:metadata, metadata)
              else
                Repo.rollback(:invalid_operator)
              end
          end
        end)

      errors ->
        {:error, {:invalid_metadata, errors}}
    end
  end

  @spec approve_claims(UserResolvable.t(), list(claim_t()), NaiveDateTime.t()) ::
          {:ok, list()} | {:error, :permission_denied | :invalid_amount | :not_enough_amount}
  defp approve_claims(_sender, [], _) do
    {:ok, []}
  end

  defp approve_claims(sender, approving_claims, time) do
    with {:verify_claim_payer, true} <-
           {:verify_claim_payer,
            approving_claims
            |> Enum.all?(fn %{
                              payer: payer
                            } ->
              UserResolvable.is?(sender, payer)
            end)},
         {:verify_current_status, true} <-
           {:verify_current_status,
            approving_claims |> Enum.all?(&(&1.claim.status == "pending"))},
         sender_id <- (approving_claims |> hd()).payer.id,
         {:transfer, {:ok, _}} <-
           {:transfer,
            VirtualCrypto.Money.Query.Asset.Transfer.transfer_bulk(
              sender_id,
              approving_claims
              |> Enum.map(fn %{
                               claim: %{
                                 amount: amount
                               },
                               payer: %{
                                 id: ^sender_id
                               },
                               claimant: %{
                                 id: receiver_id
                               },
                               currency: %{
                                 unit: unit
                               }
                             } ->
                {unit, receiver_id, amount}
              end)
            )},
         {:ok, cs} <-
           VirtualCrypto.Money.Query.Claim.update_claims_status(
             approving_claims |> Enum.map(& &1.claim.id),
             "approved",
             time
           ) do
      {:ok, cs}
    else
      {:verify_claim_payer, _} -> {:error, :permission_denied}
      {:verify_current_status, _} -> {:error, :invalid_current_status}
      {:transfer, {:error, err}} -> {:error, err}
    end
  end

  defp deny_claims(_operator, [], _time) do
    {:ok, []}
  end

  defp deny_claims(operator, denying_claims, time) do
    with {:verify_claim_payer, true} <-
           {:verify_claim_payer,
            denying_claims
            |> Enum.all?(fn %{
                              payer: payer
                            } ->
              UserResolvable.is?(operator, payer)
            end)},
         {:verify_current_status, true} <-
           {:verify_current_status, denying_claims |> Enum.all?(&(&1.claim.status == "pending"))},
         {:ok, cs} <-
           VirtualCrypto.Money.Query.Claim.update_claims_status(
             denying_claims |> Enum.map(& &1.claim.id),
             "denied",
             time
           ) do
      {:ok, cs}
    else
      {:verify_claim_payer, _} -> {:error, :permission_denied}
      {:verify_current_status, _} -> {:error, :invalid_current_status}
    end
  end

  defp cancel_claims(_operator, [], _time) do
    {:ok, []}
  end

  defp cancel_claims(operator, canceling_claims, time) do
    with {:verify_claim_claimant, true} <-
           {:verify_claim_claimant,
            canceling_claims
            |> Enum.all?(fn %{
                              claimant: claimant
                            } ->
              UserResolvable.is?(operator, claimant)
            end)},
         {:verify_current_status, true} <-
           {:verify_current_status,
            canceling_claims |> Enum.all?(&(&1.claim.status == "pending"))},
         {:ok, cs} <-
           VirtualCrypto.Money.Query.Claim.update_claims_status(
             canceling_claims |> Enum.map(& &1.claim.id),
             "canceled",
             time
           ) do
      {:ok, cs}
    else
      {:verify_claim_claimant, _} -> {:error, :permission_denied}
      {:verify_current_status, _} -> {:error, :invalid_current_status}
    end
  end

  defp update_claims_status(operator, claims, partial_claims_to_status_change, time) do
    with {:approve_claims, {:ok, approved}} <-
           {:approve_claims,
            approve_claims(
              operator,
              Map.get(partial_claims_to_status_change, "approved", [])
              |> Enum.map(fn e -> claims[e.id] end),
              time
            )},
         {:deny_claims, {:ok, denied}} <-
           {:deny_claims,
            deny_claims(
              operator,
              Map.get(partial_claims_to_status_change, "denied", [])
              |> Enum.map(fn e -> claims[e.id] end),
              time
            )},
         {:cancel_claims, {:ok, canceled}} <-
           {:cancel_claims,
            cancel_claims(
              operator,
              Map.get(partial_claims_to_status_change, "canceled", [])
              |> Enum.map(fn e -> claims[e.id] end),
              time
            )} do
      {:update_claims_status, %{approved: approved, denied: denied, canceled: canceled}}
    else
      x -> x
    end
  end

  @typep update_claims_errors_t ::
           :not_found
           | :duplicated_claims
           | :permission_denied
           | :invalid_status
           | :invalid_amount
           | :not_enough_amount
           | :invalid_operator
           | :invalid_current_status
           | {:invalid_metadata, [binary()]}
  @spec update_claims(list(partial_claim_t()), UserResolvable.t()) ::
          {:ok, list(claim_t)} | {:error, update_claims_errors_t()}
  def update_claims(partial_claims, operator) do
    time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    r =
      Repo.transaction(fn ->
        with {:prevent_duplicated_claims, x} when x != nil <-
               {:prevent_duplicated_claims,
                partial_claims
                |> Enum.map(& &1.id)
                |> Enum.reduce_while(MapSet.new(), fn elem, acc ->
                  if MapSet.member?(acc, elem) do
                    {:halt, nil}
                  else
                    {:cont, MapSet.put(acc, elem)}
                  end
                end)},
             partial_claims_grouped <- partial_claims |> Enum.group_by(& &1.status),
             {:validate_status, true} <-
               {:validate_status,
                partial_claims_grouped
                |> Map.keys()
                |> Enum.all?(&(&1 in ["approved", "denied", "canceled", nil]))},
             {:validate_metadata, []} <-
               {:validate_metadata,
                partial_claims
                |> Enum.with_index()
                |> Enum.map(fn {v, index} ->
                  validate_metadata(Map.get(v, :metadata)) |> Enum.map(&"[#{index}] #{&1}")
                end)
                |> Enum.flat_map(& &1)},
             {:get_claims, [claim | _] = claims_list} <-
               {:get_claims,
                partial_claims
                |> Enum.map(& &1.id)
                |> VirtualCrypto.Money.Query.Claim.get_claim_by_ids_with_lock()},
             {:is_exists, true} <-
               {:is_exists, claims_list |> Enum.all?(&(&1 != nil))},
             claims <-
               claims_list
               |> Map.new(&{&1.claim.id, &1}),
             {:validate_operator, true} <-
               {:validate_operator,
                claims
                |> Map.values()
                |> Enum.all?(
                  &(UserResolvable.is?(operator, &1.payer) or
                      UserResolvable.is?(operator, &1.claimant))
                )},
             operator <-
               if(UserResolvable.is?(operator, claim.claimant),
                 do: claim.claimant,
                 else: claim.payer
               ),
             claims_to_status_change <- partial_claims_grouped |> Map.drop([nil]),
             {:update_claims_status, %{approved: approved, denied: denied, canceled: canceled}} <-
               update_claims_status(operator, claims, claims_to_status_change, time),
             updated_claims <- approved ++ denied ++ canceled,
             claim_claim_metadata_pairs <-
               partial_claims
               |> Enum.filter(fn partial_claim -> Map.has_key?(partial_claim, :metadata) end)
               |> Enum.map(&{claims[&1.id], &1.metadata}) do
          update_claims_metadata_result =
            case claim_claim_metadata_pairs do
              [] ->
                {:ok, []}

              [_updated_claim | _tail] ->
                case VirtualCrypto.Money.Query.Claim.update_claims_metadata(
                       operator.id,
                       claim_claim_metadata_pairs
                     ) do
                  {:ok, _} -> {:ok, nil}
                  {:error, x} -> {:error, x}
                end
            end

          case update_claims_metadata_result do
            {:ok, _} ->
              claims_to_notify = approved ++ denied
              claim_ids_to_notify = claims_to_notify |> Enum.map(& &1.id)

              claim_metadata =
                case claims_to_notify do
                  [] ->
                    %{}

                  [hd | _] ->
                    VirtualCrypto.Money.Query.Claim.get_claims_metadata(
                      claim_ids_to_notify,
                      hd.claimant_user_id
                    )
                    |> Map.new(&{&1.claim_id, &1.metadata})
                end

              VirtualCrypto.Money.Query.Claim.get_claim_by_ids(
                operator.id,
                updated_claims |> Enum.map(& &1.id)
              )
              |> Enum.map(fn claim ->
                unless claim.claim.id in claim_ids_to_notify do
                  claim
                else
                  claim
                  |> Map.put(:claimant_metadata, Map.get(claim_metadata, claim.claim.id, %{}))
                end
              end)

            {:error, x} ->
              Repo.rollback(x)
          end
        else
          {:prevent_duplicated_claims, _} ->
            Repo.rollback(:duplicated_claims)

          {:get_claims, []} ->
            []

          {:validate_status, _} ->
            Repo.rollback(:invalid_status)

          {:validate_metadata, x} ->
            Repo.rollback({:invalid_metadata, x})

          {:is_exists, _} ->
            Repo.rollback(:not_found)

          {:validate_operator, _} ->
            Repo.rollback(:invalid_operator)

          {:approve_claims, {:error, err}} ->
            Repo.rollback(err)

          {:deny_claims, {:error, err}} ->
            Repo.rollback(err)

          {:cancel_claims, {:error, err}} ->
            Repo.rollback(err)
        end
      end)

    case r do
      {:ok, claims} ->
        claims
        |> Enum.filter(&Map.has_key?(&1, :claimant_metadata))
        |> Enum.group_by(& &1.claimant.id)
        |> Map.drop([nil])
        |> Enum.map(fn {claimant_id, claims} ->
          claims =
            claims
            |> Enum.map(fn claim ->
              {v, m} = Map.pop!(claim, :claimant_metadata)
              format_claim_for_notification(%{m | metadata: v})
            end)

          {claimant_id, claims}
        end)
        |> Enum.each(fn {claimant_id, claims} ->
          VirtualCrypto.Notification.Dispatcher.notify_claim_update(
            %VirtualCrypto.Exterior.User.VirtualCrypto{id: claimant_id},
            claims
          )
        end)

        {:ok, claims |> Enum.map(&Map.drop(&1, [:claimant_metadata]))}

      {:error, _} = err ->
        err
    end
  end

  defp validate_metadata(nil) do
    []
  end

  defp validate_metadata(%{} = d) do
    VirtualCrypto.Metadata.Validator.validate_metadata(d)
  end

  @doc """
  payer must be discord user
  """
  @spec create_claim(
          UserResolvable.t(),
          UserResolvable.t(),
          String.t(),
          pos_integer(),
          map() | nil
        ) ::
          {:ok, claim_t}
          | {:error, :not_found_currency}
          | {:error, :invalid_amount}
          | {:error, {:invalid_metadata, [binary()]}}
  def create_claim(claimant, payer, unit, amount, metadata) do
    case validate_metadata(metadata) do
      [] ->
        {:ok, x} =
          Repo.transaction(fn ->
            VirtualCrypto.Money.Query.Claim.create_claim(claimant, payer, unit, amount, metadata)
          end)

        x

      list ->
        {:error, {:invalid_metadata, list}}
    end
  end

  @spec get_claim_by_id(UserResolvable.t(), non_neg_integer()) :: claim_t | {:error, :not_found}
  def get_claim_by_id(executor, id) do
    {:ok, x} =
      Repo.transaction(fn ->
        VirtualCrypto.Money.Query.Claim.get_claim_by_id(UserResolvable.resolve_id(executor), id)
      end)

    if x do
      x
    else
      {:error, :not_found}
    end
  end

  @spec get_claim_by_ids(UserResolvable.t(), list(non_neg_integer())) :: list(claim_t | nil)
  def get_claim_by_ids(executor, ids) do
    {:ok, x} =
      Repo.transaction(fn ->
        VirtualCrypto.Money.Query.Claim.get_claim_by_ids(UserResolvable.resolve_id(executor), ids)
      end)

    x
  end
end
