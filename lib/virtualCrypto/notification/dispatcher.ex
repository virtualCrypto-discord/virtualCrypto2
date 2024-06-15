defmodule VirtualCrypto.Notification.Dispatcher do
  @behaviour VirtualCrypto.Notification.Behaviour
  @config Application.compile_env!(:virtualCrypto, __MODULE__)

  @impl VirtualCrypto.Notification.Behaviour
  def notify_claim_update(exterior, events) when is_list(events) do
    modules = Keyword.get(@config, :children, [])

    modules
    |> Enum.each(fn module ->
      module.notify_claim_update(exterior, events)
    end)
  end
end
