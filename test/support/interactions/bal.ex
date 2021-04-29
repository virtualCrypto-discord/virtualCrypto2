defmodule InteractionsControllerTest.Bal.Helper do
  import InteractionsControllerTest.Helper.Common

  defp data() do
    %{
      name: "bal",
      options: [
      ]
    }
  end

  def from_guild(sender) do
    execute_from_guild(data(), sender)
  end
end
