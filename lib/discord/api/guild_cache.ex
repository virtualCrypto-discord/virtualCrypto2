defmodule Discord.Api.GuildCache do
  def start_link(options) do
    options = [{:name, __MODULE__} | options]
    Cachex.start_link(options)
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  def get_guild(guild_id, service) do
    Cachex.transaction!(__MODULE__, [guild_id], fn cache ->
      case Cachex.get!(cache, guild_id) do
        nil ->
          case service.get_guild_with_status_code(guild_id) do
            {200, data} ->
              Cachex.put!(cache, guild_id, {:found, data})
              data

            {404, _} ->
              Cachex.put!(cache, guild_id, :not_found)
              nil

            _ ->
              nil
          end

        :not_found ->
          nil

        {:found, data} ->
          data
      end
    end)
  end
end
