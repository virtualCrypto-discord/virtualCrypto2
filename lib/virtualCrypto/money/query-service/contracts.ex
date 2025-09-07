defmodule VirtualCrypto.Money.QueryService.Contracts do
  alias VirtualCrypto.Money.Currency
  alias VirtualCrypto.Money.DepositAgreement
  alias VirtualCrypto.Money.Contractor
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Money.Contract
  alias VirtualCrypto.Exterior.User.Resolver, as: UserResolver
  alias VirtualCrypto.Exterior.User.Resolvable, as: UserResolvable
  import Ecto.Query

  @type contract_create_t() :: [
          %{
            contractor: UserResolvable.t(),
            deposits: [
              %{
                deposit_amount: non_neg_integer(),
                currency: %VirtualCrypto.Money.Currency{}
              }
            ]
          }
        ]

  @typedoc """
  unclosed | closed
  """
  @type deposit_status_t() :: String.t()
  @type contract_t() :: %{
          intermediate: %VirtualCrypto.User.User{},
          contractors: [
            %{
              contractor: %VirtualCrypto.User.User{},
              deposits: [
                %{
                  deposit_amount: non_neg_integer(),
                  executed_amount: non_neg_integer(),
                  status: deposit_status_t(),
                  currency: %VirtualCrypto.Money.Currency{}
                }
              ]
            }
          ]
        }
  @spec get_contract(non_neg_integer()) :: {:ok, contract_t()} | {:error, :not_found}
  def get_contract(contract_id) do
    query =
      from(contract in Contract,
        join: contractor in Contractor,
        on: contractor.contract_id == contract.id,
        join: users in VirtualCrypto.User.User,
        on: contractor.user_id == users.id,
        join: intermediate_app in VirtualCrypto.Auth.Application,
        on: contract.intermediary_id == intermediate_app.id,
        left_join: deposit_agreement in DepositAgreement,
        on: deposit_agreement.contractor_id == contractor.id,
        left_join: currency in Currency,
        on: deposit_agreement.currency_id == currency.id,
        where: contract.id == ^contract_id,
        select: %{
          contract: contract,
          contractor: contractor,
          users: users,
          deposit_agreement: deposit_agreement,
          intermediate_app: intermediate_app,
          currency: currency
        }
      )

    case Repo.all(query) do
      [] ->
        {:error, :not_found}

      query_results ->
        first_result = hd(query_results)
        intermediate_app = first_result.intermediate_app

        contractors_list =
          query_results
          |> Enum.group_by(
            & &1.contractor.id,
            &%{
              user: &1.users,
              deposit_agreement: &1.deposit_agreement,
              currency: &1.currency
            }
          )
          |> Enum.map(fn {_user, deposits_data} ->
            deposits_list =
              deposits_data
              |> Enum.filter(& &1.deposit_agreement)
              |> Enum.map(fn %{deposit_agreement: da, currency: c} ->
                %{
                  deposit_amount: da.deposit_amount,
                  executed_amount: da.executed_amount,
                  status: da.status,
                  currency: c
                }
              end)

            head = hd(deposits_data)

            %{
              user: head.user,
              deposits: deposits_list
            }
          end)

        result = %{
          contract: first_result.contract,
          intermediate: intermediate_app,
          contractors: contractors_list
        }

        {:ok, result}
    end
  end

  defp all_unique?(list) do
    length(list) == MapSet.size(MapSet.new(list))
  end

  @spec create_contract(non_neg_integer(), contract_create_t()) ::
          {:ok, contract_t()} | {:error, term()}
  def create_contract(intermediary_id, %{contractors: contractors}) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    with {_, true} <-
           {:valid_deposit_amount,
            contractors
            |> Enum.flat_map(fn e -> e.deposits end)
            |> Enum.all?(fn e -> e.deposit_amount >= 0 end)},
         {:ok, created_contract} =
           %Contract{
             intermediary_id: intermediary_id
           }
           |> Repo.insert(returning: [:id]),
         contract_id = created_contract.id,
         contractor_user_ids =
           UserResolver.resolve_ids(
             contractors
             |> Enum.map(fn x -> %VirtualCrypto.Exterior.User.Discord{id: x.discord_id} end)
           ),
         {_, true} <- {:unique_contractors, all_unique?(contractor_user_ids)},
         contractors_to_insert =
           contractor_user_ids
           |> Enum.map(fn id ->
             %{
               status: "unclosed",
               contract_id: contract_id,
               user_id: id,
               inserted_at: now,
               updated_at: now
             }
           end),
         {_, created_contractors} =
           Repo.insert_all(Contractor, contractors_to_insert, returning: [:user_id, :id]),
         user_id_contractor_id_map =
           created_contractors |> Map.new(fn e -> {e.user_id, e.id} end),
         deposit_agreements =
           contractors
           |> Enum.zip(contractor_user_ids)
           |> Enum.flat_map(fn {e, user_id} ->
             contractor_id = user_id_contractor_id_map[user_id]

             e.deposits
             |> Enum.map(fn x ->
               %DepositAgreement{
                 contractor_id: contractor_id,
                 currency_id: x.currency_id,
                 deposit_amount: x.deposit_amount,
                 executed_amount: 0
               }
             end)
           end),
         {_, _} = Repo.insert_all(DepositAgreement, deposit_agreements) do
      get_contract(contract_id)
    else
      {error, _} -> {:error, error}
    end
  end

  @spec agree_contract(non_neg_integer(), UserResolvable.t()) :: any()
  def agree_contract(contract_id, contractor) do
    contractor_id = UserResolvable.resolve_id(contractor)

    query =
      from(
        contractors in Contractor,
        left_join: deposit_agreement in DepositAgreement,
        on:
          contractors.contract_id == ^contract_id and contractors.user_id == ^contractor_id and
            contractors.id == deposit_agreement.contractor_id,
        select: {contractors.status, deposit_agreement},
        lock: fragment("FOR UPDATE OF ?", deposit_agreement)
      )

    with deposit_agreements = Repo.all(query),
         # contains user? if not, return error
         {_, true} <- {:contract_not_found, Enum.empty?(deposit_agreements)},
         # is contractor status be pending? if not, return error
         {_, {"unclosed", _}} <- {:invalid_contractor_status, Enum.fetch!(deposit_agreements, 0)},
         contract_user_id =
           UserResolvable.resolve_id(%VirtualCrypto.Exterior.User.Contract{id: contract_id}),
         # transfer user account balance to contract account. if failed, return error
         {_, {:ok, _}} <-
           {:transfer,
            VirtualCrypto.Query.Asset.Transfer.transfer_bulk_by_id(
              contractor_id,
              deposit_agreements
              |> Enum.map(fn {_,
                              %{
                                currency_id: currency_id,
                                deposit_amount: amount
                              }} ->
                {currency_id, contract_user_id, amount}
              end)
            )},
         # update deposit agreement
         _ =
           Repo.update(
             deposit_agreements
             |> Enum.map(fn {_, x} ->
               DepositAgreement.changeset(x, %{executed_amount: x.deposit_amount})
             end)
           ) do
      {:ok, nil}
    else
      {:transfer, {:error, error}} -> {:error, error}
      {error, _} -> {:error, error}
    end
  end

  # TODO: if contract is executed or canceled. MUST set all contactor status be closed.

  @spec close_contract(non_neg_integer(), non_neg_integer()) :: any()
  def close_contract(intermediary_id, contract_id) do
    query =
      from(
        contract in Contract,
        join: contractors in Contractor,
        on:
          contract.id == ^contract_id and contract.intermediary_id == ^intermediary_id and
            contract.id == contractors.contract_id,
        left_join: deposit_agreement in DepositAgreement,
        on: contractors.id == deposit_agreement.contractor_id,
        select: {contractors, deposit_agreement},
        lock: fragment("FOR UPDATE OF ?,?", contractors, deposit_agreement)
      )

    with deposit_agreements = Repo.all(query),
         contract_user_id =
           UserResolvable.resolve_id(%VirtualCrypto.Exterior.User.Contract{id: contract_id}),
         # transfer contract account balance to user account. expected never fails.
         {_, {:ok, _}} <-
           {:transfer,
            VirtualCrypto.Query.Asset.Transfer.transfer_bulk_by_id(
              contract_user_id,
              deposit_agreements
              |> Enum.map(fn {_,
                              %{
                                user_id: user_id,
                                currency_id: currency_id,
                                executed_amount: amount
                              }} ->
                {currency_id, user_id, amount}
              end)
            )},

         # update deposit agreement
         _ =
           Repo.update(
             deposit_agreements
             |> Enum.map(fn {_, x} ->
               DepositAgreement.changeset(x, %{executed_amount: 0})
             end)
           ),
         _ =
           Repo.update(
             deposit_agreements
             |> Enum.map(fn {x, _} -> Contractor.changeset(x, %{status: "closed"}) end)
           ) do
      {:ok, nil}
    else
      {:transfer, {:error, error}} -> {:error, error}
      {error, _} -> {:error, error}
    end
  end
end
