defmodule InteractionsControllerTest.Helper.Common do
  def execute_from_guild(data, user) do
    %{
      type: 2,
      data: data,
      member: %{
        user: %{
          id: to_string(user)
        }
      }
    }
  end
end
