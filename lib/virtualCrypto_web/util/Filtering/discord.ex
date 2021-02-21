defmodule VirtualCryptoWeb.Filtering.Disocrd do
  def user(user) do
    Map.take(user, [
      "id",
      "username",
      "discriminator",
      "avatar",
      "bot",
      "system",
      "mfa_enabled",
      "premium_type",
      "public_flags"
    ])
  end
end
