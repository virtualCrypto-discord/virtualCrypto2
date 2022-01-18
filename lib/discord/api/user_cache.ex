defmodule Discord.Api.UserCache do
  defmodule Worker do
    use GenServer

    @impl GenServer
    def init(wait_list) do
      {:ok, wait_list}
    end

    @impl GenServer
    def handle_call(:wait, from, wait_list) do
      {:noreply, [from | wait_list]}
    end

    @impl GenServer
    def handle_cast({:done, data}, wait_list) do
      Enum.each(wait_list, fn client ->
        GenServer.reply(client, data)
      end)

      {:stop, :normal, nil}
    end

    @impl GenServer
    def handle_cast({:kick, {user_id, service, mod}}, wait_list) do
      pid = self()

      Task.start(fn ->
        res = service.get_user_with_status(user_id)

        d =
          case res do
            {200, data} ->
              Cachex.put(mod, user_id, {:cached, data})
              data

            {404, _} ->
              Cachex.put(mod, user_id, {:cached, nil})
              nil

            _ ->
              nil
          end

        GenServer.cast(pid, {:done, d})
      end)

      {:noreply, wait_list}
    end

    def start(user_id, service, mod) do
      {:ok, pid} = GenServer.start_link(__MODULE__, [])
      GenServer.cast(pid, {:kick, {user_id, service, mod}})
      pid
    end

    def wait(pid, timeout \\ 5000) do
      GenServer.call(pid, :wait, timeout)
    end
  end

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

  defp do_fetch(user_id, service) do
    Worker.start(user_id, service, __MODULE__)
  end

  def get_user(user_id, service) do
    case Cachex.get_and_update(
           __MODULE__,
           user_id,
           fn
             nil -> {:commit, {:fetching, do_fetch(user_id, service)}}
             {:fetching, _} = st -> {:ignore, st}
             {:cached, _} = st -> {:ignore, st}
           end
         ) do
      {_, {:fetching, task}} ->
        Worker.wait(task)

      {_, {:cached, data}} ->
        data
    end
  end
end
