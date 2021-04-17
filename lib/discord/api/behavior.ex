defmodule Discord.Api.Behavior do
  @type service() :: module()
  @type guild_id :: pos_integer()
  @type user_id :: pos_integer()
  @type limit :: pos_integer()
  @type status_code :: pos_integer()
  @type guild :: map()
  @type user :: map()
  @type integration :: map()
  @type guild_member :: map()
  @type role :: map()
  @type with_counts :: boolean()
  @callback get_guild_member_with_status_code(guild_id, user_id) ::
              {status_code, guild_member}
  @callback get_roles(guild_id) :: [role]
  @callback get_guild(guild_id) :: guild
  @callback get_guild(guild_id, with_counts) :: guild
  @callback get_guild_with_status_code(guild_id) :: {status_code, guild}
  @callback get_guild_with_status_code(guild_id, with_counts) :: {status_code, guild}
  @callback get_user(user_id()) :: user
  @callback get_user_with_status(user_id()) :: {status_code(), user}
  @callback get_guild_integrations_with_status_code(guild_id()) :: {status_code(), [integration]}
end
