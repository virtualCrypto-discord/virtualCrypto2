defmodule InteractionsControllerTest.Create.Helper do
  import InteractionsControllerTest.Helper.Common

  defp create_data(%{amount: amount, unit: unit, name: name}) do
    %{
      name: "create",
      options: [
        %{
          name: "amount",
          value: amount
        },
        %{
          name: "unit",
          value: unit
        },
        %{
          name: "name",
          value: name
        }
      ]
    }
  end

  def from_guild(m, sender, guild \\ 494_780_225_280_802_817, permissions \\ 0xFFFFFFFFFFFFFFFF) do
    execute_from_guild(m |> create_data, sender, guild, permissions)
  end
end
