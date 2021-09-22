defmodule VirtualCryptoTest.Notification.Setup do
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser

  def setup_claim(%{
        unit: unit,
        amount: amount,
        metadata: metadata,
        receiver: receiver,
        payer: payer
      }) do
    VirtualCrypto.Money.create_claim(
      %DiscordUser{id: receiver},
      %DiscordUser{id: payer},
      unit,
      amount,
      metadata
    )
  end
end
