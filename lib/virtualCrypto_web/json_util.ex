defmodule VirtualCryptoWeb.JsonUtil do
  @max_safe_integer 9007199254740991
  defguard is_safe_integer(v) when is_integer(v) and -@max_safe_integer <= v and v <= @max_safe_integer
  def to_integer(v) when is_binary(v) do
    String.to_integer(v)
  end

  def to_integer(v) when is_safe_integer(v) do
    v
  end
  def to_integer(_) do
    :error
  end
  def parse_to_integer(v) when is_binary(v) do
    case Integer.parse(v) do
      {v, ""} -> v
      _ -> :error
    end
  end
  def parse_to_integer(v) when is_safe_integer(v) do
    v
  end
  def parse_to_integer(_) do
    :error
  end
end
