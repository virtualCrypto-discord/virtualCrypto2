defmodule VirtualCrypto.Auth.InternalAction.Util do
  def make_secure_random_code() do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
