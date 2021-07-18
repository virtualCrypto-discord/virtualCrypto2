defmodule VirtualCryptoWeb.CustomIdText do
  # Use the module
  use ExUnit.Case, async: true

  test "custom_id" do
    for a <- 0..255, b <- 0..255, c <- 0..127 do
      VirtualCryptoWeb.Interaction.CustomId.encode(<<a, b, c>>)
    end

    VirtualCryptoWeb.Interaction.CustomId.encode(<<255, 255, 255, 255, 255>>)
  end
end
