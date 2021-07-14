defmodule VirtualCryptoWeb.Interaction.Claim.Helper do
  def destructuring_claim_ids(claim_ids) do
    Stream.unfold(claim_ids, fn
      <<>> -> nil
      <<claim_id::64-integer, rest::binary>> -> {claim_id, rest}
    end)
    |> Enum.to_list()
  end


  defp join_bytes(enum) do
    Enum.reduce(enum, <<>>, fn elem, acc -> acc <> elem end)
  end

  def encode_claim_ids(claims) do
    claim_count = claims |> Enum.count()
    <<claim_count::8>> <> (claims |> Enum.map(&<<&1.claim.id::64>>) |> join_bytes)
  end
end
