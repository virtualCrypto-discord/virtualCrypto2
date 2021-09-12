defmodule Discord.Api.Behaviour do
  @type service() :: module()
  @type guild_id :: pos_integer()
  @type user_id :: pos_integer()
  @type limit :: pos_integer()
  @type status_code :: pos_integer()
  @type application_id :: pos_integer()
  @type interaction_token :: String.t()
  @type message_id :: pos_integer()
  @type webhook_message_id :: message_id() | :original
  @type guild :: map()
  @type user :: map()
  @type integration :: map()
  @type guild_member :: map()
  @type role :: map()
  @type message :: map()
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
  @callback patch_webhook_message(
              application_id(),
              interaction_token(),
              webhook_message_id(),
              message()
            ) :: {status_code(), message()}
  @callback post_webhook_message(
              application_id(),
              interaction_token(),
              message()
            ) :: {status_code(), message()}
end
