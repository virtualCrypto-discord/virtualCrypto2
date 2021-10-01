defmodule InteractionsControllerTest.Info.Helper do
  import InteractionsControllerTest.Helper.Common

  defp data(options \\ []) do
    %{
      name: "info",
      options: options
    }
  end

  def from_guild(sender, guild_id) do
    execute_from_guild(data(), sender, guild_id)
  end

  def from_dm(sender) do
    execute_from_dm(data(), sender)
  end

  def from_guild_name(name, sender, guild_id) do
    execute_from_guild(
      data([
        %{
          name: "name",
          value: name
        }
      ]),
      sender,
      guild_id
    )
  end

  def from_guild_unit(unit, sender, guild_id) do
    execute_from_guild(
      data([
        %{
          name: "unit",
          value: unit
        }
      ]),
      sender,
      guild_id
    )
  end

  def from_guild_name_unit(name, unit, sender, guild_id) do
    execute_from_guild(
      data([
        %{
          name: "name",
          value: name
        },
        %{
          name: "unit",
          value: unit
        }
      ]),
      sender,
      guild_id
    )
  end
end
