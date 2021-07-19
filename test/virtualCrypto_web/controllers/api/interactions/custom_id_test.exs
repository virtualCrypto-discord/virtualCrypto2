defmodule VirtualCryptoWeb.CustomIdTest do
  use ExUnit.Case, async: true
  alias VirtualCryptoWeb.Interaction.CustomId
  test "custom_id" do
    for a <- 0..255, b <- 0..255, c <- 0..127 do
      assert <<a,b,c,0,0>> == CustomId.parse(CustomId.encode(<<a, b, c>>))
    end

    assert <<255,255,255,255,255>> == CustomId.encode(<<255, 255, 255, 255, 255>>)
  end
end
