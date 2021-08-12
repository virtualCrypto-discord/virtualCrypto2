defmodule VirtualCrypto.Notification.Webhook.Behaviour do
  @type requester :: non_neg_integer()
  @type webhook_url :: binary()
  @type public_key :: binary()
  @type private_key :: binary()

  @callback verify(requester, webhook_url, public_key, private_key) ::
              :ok | {:error, {atom(), atom()} | atom()}
end
