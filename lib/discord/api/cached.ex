defmodule Discord.Api.Cached do
  @spec get_user(Discord.Api.Behaviour.user_id(), Discord.Api.Behaviour.service()) ::
          Discord.Api.Behaviour.user()
  def get_user(user_id, service \\ Discord.Api.Raw) do
    Discord.Api.UserCache.get_user(user_id, service)
  end

  def get_guild(guild_id, service \\ Discord.Api.Raw) do
    Discord.Api.GuildCache.get_guild(guild_id, service)
  end
end
