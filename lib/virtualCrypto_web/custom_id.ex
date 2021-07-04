defmodule VirtualCryptoWeb.CustomId do
  use Bitwise

  # buttons
  def claim_list(:all), do: <<0xF0, 1>>
  def claim_list(:received), do: <<0xF0, 2>>
  def claim_list(:sent), do: <<0xF0, 3>>
  def claim_action(:approve), do: <<0xF0, 4>>
  def claim_action(:deny), do: <<0xF0, 5>>
  def claim_action(:cancel), do: <<0xF0, 6>>
  def claim_action(:back), do: <<0xF0, 7>>

  defp parse_button_long(<<h1, h2, data::binary>>) do
    case (h1 &&& 0x0F) <<< 8 ||| h2 do
      1 -> {[:claim, :list, :all], data}
      2 -> {[:claim, :list, :received], data}
      3 -> {[:claim, :list, :sent], data}
      4 -> {[:claim, :action, :approve], data}
      5 -> {[:claim, :action, :deny], data}
      6 -> {[:claim, :action, :cancel], data}
      7 -> {[:claim, :action, :back], data}
    end
  end

  def parse_button(<<head, _rest::binary>> = source) do
    case head >>> 4 do
      0x0F -> parse_button_long(source)
      _ -> {:error, :head}
    end
  end

  # select menus
  def claim_select(), do: <<0xF0, 1>>

  defp parse_select_menu_long(<<h1, h2, data::binary>>) do
    case (h1 &&& 0x0F) <<< 8 ||| h2 do
      1 -> {[:claim, :select], data}
    end
  end

  def parse_select_menu(<<head, _rest::binary>> = source) do
    case head >>> 4 do
      0x0F -> parse_select_menu_long(source)
      _ -> {:error, :head}
    end
  end

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
    |> List.to_string()
  end

  def parse(bytes) do
    bytes
    |> String.to_charlist()
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
