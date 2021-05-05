defmodule VirtualCryptoWeb.IdempotencyLayer.Validator do
  @regex ~r/^"([\!#-~\x80-\xFF]{0,256})"$/

  def extract_idempotency_key(idempotency_key) do
    case Regex.run(@regex, idempotency_key) do
      nil -> nil
      [_, idempotency_key] -> idempotency_key
    end
  end
end
