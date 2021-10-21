defmodule VirtualCrypto.Money.Query.Util do
  defguard is_non_neg_integer(v) when is_integer(v) and v >= 0
  defguard is_positive_integer(v) when is_integer(v) and v > 0

  def escape_like_query(q) do
    String.replace(q, ["%", "_", "\\"], fn <<char>> -> <<"\\", char>> end)
  end
end
