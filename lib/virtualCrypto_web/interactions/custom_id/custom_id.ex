defmodule VirtualCryptoWeb.Interaction.CustomId do
  use Bitwise

  def encode(bytes) do
    Stream.unfold(bytes, fn
      <<>> -> nil
      <<a::20-integer, b::20-integer, rest::binary>> -> {[a, b], rest}
      <<a::20-integer, b::12-integer>> -> {[a, b <<< 8], <<>>}
      <<a::20-integer, b::4-integer>> -> {[a, b <<< 16], <<>>}
      <<a::16-integer>> -> {[a <<< 4], <<>>}
      <<a::8-integer>> -> {[a <<< 12], <<>>}
    end)
    |> Enum.flat_map(&Function.identity/1)
    |> Enum.map(&(&1 + 65536))
    |> List.to_string()
  end

  def parse(bytes) do
    bytes
    |> String.to_charlist()
    |> Enum.map(&(&1 - 65536))
    |> Stream.chunk_every(2)
    |> Stream.map(fn
      [a, b] ->
        <<(a &&& 0xFF000) >>> 12, (a &&& 0x00FF0) >>> 4,
          (a &&& 0x0000F) <<< 4 ||| (b &&& 0xF0000) >>> 16, (b &&& 0x0FF00) >>> 8, b &&& 0x000FF>>

      [a] ->
        <<(a &&& 0xFF000) >>> 12, (a &&& 0x00FF0) >>> 4, (a &&& 0x0000F) <<< 4, 0, 0>>
    end)
    |> Enum.join()
  end
end
