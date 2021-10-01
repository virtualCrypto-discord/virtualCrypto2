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

  def component_from_guild(
        data,
        user,
        guild_id \\ 494_780_225_280_802_817,
        permissions \\ 0xFFFFFFFFFFFFFFFF
      ) do
    %{
      type: 3,
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

  def select_from_guild(
        data,
        user,
        guild_id \\ 494_780_225_280_802_817,
        permissions \\ 0xFFFFFFFFFFFFFFFF
      ) do
    %{
      type: 3,
      data: data |> Map.put(:component_type, 3),
      member: %{
        user: %{
          id: to_string(user)
        },
        permissions: to_string(permissions)
      },
      guild_id: to_string(guild_id)
    }
  end

  def button_from_guild(
        data,
        user,
        guild_id \\ 494_780_225_280_802_817,
        permissions \\ 0xFFFFFFFFFFFFFFFF
      ) do
    %{
      type: 3,
      data: data |> Map.put(:component_type, 2),
      member: %{
        user: %{
          id: to_string(user)
        },
        permissions: to_string(permissions)
      },
      guild_id: to_string(guild_id)
    }
  end

  def execute_from_dm(
        data,
        user
      ) do
    %{
      type: 2,
      data: data |> Map.put(:component_type, 2),
      user: %{
        id: to_string(user)
      }
    }
  end
end
