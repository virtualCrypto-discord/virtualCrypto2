defmodule VirtualCryptoTest.Notification.Sink do
  @behaviour VirtualCrypto.Notification.Behaviour

  @impl VirtualCrypto.Notification.Behaviour
  def notify_claim_update(exterior, events) when is_list(events) do
    send(self(), {:notification_sink, exterior, events})
  end
end
