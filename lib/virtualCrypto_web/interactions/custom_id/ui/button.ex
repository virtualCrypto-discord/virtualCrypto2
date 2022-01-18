defmodule VirtualCryptoWeb.Interaction.CustomId.UI.Button do
  use Bitwise

  # buttons
  def claim_list(:all), do: <<0xF0, 1>>
  def claim_list(:received), do: <<0xF0, 2>>
  def claim_list(:claimed), do: <<0xF0, 3>>
  def claim_action(:approve), do: <<0xF0, 4>>
  def claim_action(:deny), do: <<0xF0, 5>>
  def claim_action(:cancel), do: <<0xF0, 6>>
  def claim_action(:back), do: <<0xF0, 7>>

  defp parse_long(<<h1, h2, data::binary>>) do
    case (h1 &&& 0x0F) <<< 8 ||| h2 do
      1 -> {[:claim, :list, :all], data}
      2 -> {[:claim, :list, :received], data}
      3 -> {[:claim, :list, :claimed], data}
      4 -> {[:claim, :action, :approve], data}
      5 -> {[:claim, :action, :deny], data}
      6 -> {[:claim, :action, :cancel], data}
      7 -> {[:claim, :action, :back], data}
    end
  end

  def parse(<<head, _rest::binary>> = source) do
    case head >>> 4 do
      0x0F -> parse_long(source)
      _ -> {:error, :head}
    end
  end
end
