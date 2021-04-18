defmodule InteractionsControllerTest.Pay.Helper do
  import InteractionsControllerTest.Helper.Common

  defp pay_data(%{receiver: receiver, amount: amount, unit: unit}) do
    %{
      name: "pay",
      options: [
        %{
          name: "user",
          value: to_string(receiver)
        },
        %{
          name: "amount",
          value: amount
        },
        %{
          name: "unit",
          value: unit
        }
      ]
    }
  end

  def from_guild(m, sender) do
    execute_from_guild(m |> pay_data, sender)
  end
end
