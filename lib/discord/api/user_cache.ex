defmodule Discord.Api.UserCache do
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

  def get_user(user_id, service) do
    Cachex.transaction!(__MODULE__, [user_id], fn cache ->
      case Cachex.get!(cache, user_id) do
        nil ->
          case service.get_user_with_status(user_id) do
            {200, data} ->
              Cachex.put!(cache, user_id, {:found, data})
              data

            {404, _} ->
              Cachex.put!(cache, user_id, :not_found)
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
