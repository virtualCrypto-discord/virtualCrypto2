defmodule VirtualCrypto.Notification.Behaviour do
  @type event() :: %{
          type: 2,
          data: %{
            id: pos_integer(),
            status: :approved | :denied,
            amount: binary(),
            updated_at: binary(),
            payer: %{
              id: pos_integer(),
              discord: %{
                id: pos_integer()
              }
            },
            currency: %{
              id: pos_integer(),
              unit: binary(),
              name: binary(),
              guild: binary(),
              pool_amount: binary()
            }
          }
        }
  @callback notify_claim_update(VirtualCrypto.Exterior.User.Resolvable.t(), [event()]) :: any()
end
