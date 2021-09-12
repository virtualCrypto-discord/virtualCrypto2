defmodule VirtualCrypto.Notification.Dispatcher do
  @behaviour VirtualCrypto.Notification.Behaviour

  @impl VirtualCrypto.Notification.Behaviour
  def notify_claim_update(exterior, events) when is_list(events) do
    Task.start(fn ->
      VirtualCrypto.Notification.Webhook.CloudflareWorkers.notify_claim_update(exterior, events)
    end)
  end
end
