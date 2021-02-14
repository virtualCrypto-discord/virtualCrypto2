defmodule Discord.Api.V8 do
  alias Discord.Api.V8.Raw

  def get_guild_members(guild_id, limit \\ 1000) do
    Raw.get_guild_members(guild_id, limit)
  end

  def get_guild_member_with_status_code(guild_id, user_id) do
    Raw.get_guild_member_with_status_code(guild_id, user_id)
  end

  def roles(guild_id) do
    Raw.roles(guild_id)
  end

  def get_guild(guild_id, with_counts \\ false) do
    Raw.get_guild(guild_id, with_counts)
  end

  def get_user(user_id) do
    case Cachex.get!(:discord_users, user_id) do
      nil ->
        user = Raw.get_user(user_id)
        Cachex.put!(:discord_users, String.to_integer(user["id"]), user)
        user

      user ->
        user
    end
  end
end
