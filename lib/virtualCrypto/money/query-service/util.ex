defmodule VirtualCrypto.Money.Query.Util do
  defguard is_non_neg_integer(v) when is_integer(v) and v >= 0
  defguard is_positive_integer(v) when is_integer(v) and v > 0
end
