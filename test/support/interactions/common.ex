defmodule InteractionsControllerTest.Helper.Common do
  def execute_from_guild(
        data,
        user,
        guild_id \\ 494_780_225_280_802_817,
        permissions \\ 0xFFFFFFFFFFFFFFFF
      ) do
    %{
      type: 2,
      data: data,
      member: %{
        user: %{
          id: to_string(user)
        },
        permissions: to_string(permissions)
      },
      guild_id: to_string(guild_id)
    }
  end
end
