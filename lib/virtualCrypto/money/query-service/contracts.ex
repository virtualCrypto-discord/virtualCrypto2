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
  live | completed
  """
  @type contract_status_t() :: String.t()
  @typedoc """
  pending | accepted | denied | canceled
  """
  @type deposit_status_t() :: String.t()
  @type contract_t() :: %{
          intermediate: %VirtualCrypto.User.User{},
          status: contract_status_t(),
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
  @spec get_contract(non_neg_integer()) :: {:ok, contract_t()}
  def get_contract(contract_id) do
    query =
      from(contract in Contract,
        join: contractor in Contractor,
        on: contractor.contract_id == contract.id,
        join: users in VirtualCrypto.User.User,
        on: contractor.user_id == users.id,
        left_join: deposit_agreement in DepositAgreement,
        on: deposit_agreement.contractor_id == contractor.id,
        left_join: currency in Currency,
        on: deposit_agreement.currency_id == currency.id,
        where: contract.id == ^contract_id,
        select: %{
          contract: contract,
          contractor: contractor,
          deposit_agreement: deposit_agreement,
          currency: currency
        }
      )

    query |> Repo.one()
  end

  @spec create_contract(non_neg_integer(), contract_create_t()) ::
          {:ok, contract_t()} | {:error, term()}
  def create_contract(intermediary_id, contract) do
    with {_, true} <-
           {:valid_deposit_amount,
            contract
            |> Enum.flat_map(fn e -> e.deposits end)
            |> Enum.all?(fn e -> e.deposit_amount >= 0 end)},
         {:ok, [contract_id]} =
           %Contract{
             status: "live",
             intermediary_id: intermediary_id
           }
           |> Repo.insert(returning: [:id]),
         contractor_user_ids =
           UserResolver.resolve_ids(contract |> Enum.map(fn x -> x.contractor end)),
         {_, true} <- {:unique_contractors, Stream.dedup(contractor_user_ids) |> Enum.empty?()},
         contractors =
           contractor_user_ids
           |> Enum.map(fn id ->
             %Contractor{
               status: "pending",
               contract_id: contract_id,
               user_id: id
             }
           end),
         {_, contractors} = Repo.insert_all(Contractor, contractors, returning: [:user_id, :id]),
         contractors = contractors |> Map.new(fn [user_id, id] -> {user_id, id} end),
         deposit_agreements =
           contract
           |> Enum.zip(contractor_user_ids)
           |> Enum.flat_map(fn {e, user_id} ->
             contractor_id = contractors[user_id]

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
end
