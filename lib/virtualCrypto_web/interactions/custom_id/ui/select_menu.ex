defmodule VirtualCryptoWeb.Interaction.CustomId.UI.SelectMenu do
  use Bitwise
  # select menus
  def claim_select(), do: <<0xF0, 1>>

  defp parse_long(<<h1, h2, data::binary>>) do
    case (h1 &&& 0x0F) <<< 8 ||| h2 do
      1 -> {[:claim, :select], data}
    end
  end

  def parse(<<head, _rest::binary>> = source) do
    case head >>> 4 do
      0x0F -> parse_long(source)
      _ -> {:error, :head}
    end
  end
end
