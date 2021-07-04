defmodule VirtualCryptoWeb.Interaction.Claim.Helper do
  def destructuring_claim_ids(claim_ids) do
    Stream.unfold(claim_ids, fn
      <<>> -> nil
      <<claim_id::64-integer, rest::binary>> -> {claim_id, rest}
    end)
    |> Enum.to_list()
  end

  def drop_tail_0(bytes) do
    bytes
    |> String.codepoints()
    |> Enum.reverse()
    |> Enum.drop_while(&(&1 == "\u0000"))
    |> Enum.reverse()
    |> List.to_string()
  end
end
