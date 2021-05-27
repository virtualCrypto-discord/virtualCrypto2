defmodule Discord.Api.Cached do
  @spec get_user(Discord.Api.Behavior.user_id(), Discord.Api.Behavior.service()) ::
          Discord.Api.Behavior.user()
  def get_user(user_id, service \\ Discord.Api.Raw) do
    case Cachex.get!(:discord_users, user_id) do
      nil ->
        user = service.get_user(user_id)
        Cachex.put!(:discord_users, String.to_integer(user["id"]), user)
        user

      user ->
        user
    end
  end
end
